#!/usr/bin/env bash
# Tests for dbtunnel and the tunnel handling in pgro, with a fake service file and a fake
# kubectl (socat forwarding to the local server on localhost:5432, which must be running).
# Uses systemd user units dbtunnel-<port> on ports 25431..25434.
#   bash tests/dbtunnel_test.sh
set -uo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
p_ok=25431 p_foreign=25432 p_fail=25433 p_bad=25434
run_dir=${XDG_RUNTIME_DIR:-/tmp/dbtunnel-$UID}/dbtunnel
cleanup() {
    for p in $p_ok $p_foreign $p_fail $p_bad; do
        systemctl --user stop "dbtunnel-$p.service" 2>/dev/null
        rm -f "$run_dir/$p.log" "$run_dir/port-$p.lock" "$run_dir/idle-$p"
    done
    [ -n "${foreign_pid:-}" ] && kill "$foreign_pid" 2>/dev/null
    pkill -f "$tmp/bin/aws" 2>/dev/null
    rm -f "$run_dir/sso-fakeprofile.lock" "$run_dir/sso-fakeprofile.log"
    # the reaper timer stops itself, but do not leave it behind when no tunnel is left
    [ -z "$(systemctl --user list-units --plain --no-legend --state=active 'dbtunnel-[0-9]*.service')" ] &&
        systemctl --user stop dbtunnel-reap.timer 2>/dev/null
    rm -rf "$tmp"
}
trap cleanup EXIT
pg_isready -q -h localhost -p 5432 || { echo "skipped: no local server on localhost:5432"; exit 0; }

# fake kubectl: forwards L to the local server; fails like an expired token when $tmp/bin/fail exists
mkdir -p "$tmp/bin"
cat >"$tmp/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
dir=$(dirname "$0")
if [ "$1" = config ]; then [ -e "$dir/sso" ] && echo fakeprofile; exit 0; fi
if [ -e "$dir/fail" ]; then echo "error: fake failure: Unauthorized" >&2; exit 1; fi
if [ -e "$dir/sso" ]; then echo "Error when retrieving token from sso: Token has expired and refresh failed" >&2; exit 1; fi
ports=${!#}
echo "Forwarding from 127.0.0.1:${ports%%:*} -> ${ports#*:}"
exec socat "TCP-LISTEN:${ports%%:*},bind=127.0.0.1,fork,reuseaddr" TCP:127.0.0.1:5432
EOF
# fake aws: the session is expired and the login stays pending (until killed)
cat >"$tmp/bin/aws" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
    "sts get-caller-identity") exit 1 ;;
    "sso login") printf 'open https://device.example/?code=ABCD-1234\nThen enter the code:\nABCD-1234\n'; sleep 300 & trap 'kill $!' TERM; wait ;;
esac
exit 1
EOF
chmod +x "$tmp/bin/kubectl" "$tmp/bin/aws"
export PATH=$tmp/bin:$PATH PGSERVICEFILE=$tmp/pg_service.conf

write_services() { # remote port of t_ok
    cat >"$PGSERVICEFILE" <<EOF
[mine]
host=elsewhere

# BEGIN dadbod (generated from connections.yaml, do not edit)
# dadbod: tunnel kube fake-ctx ns svc/pg $p_ok $1
# dadbod: read-write
[t_ok]
host=localhost
port=$p_ok

# dadbod: read-write
# dadbod: tunnel kube fake-ctx ns svc/pg $p_foreign 5432
[t_foreign]
host=localhost
port=$p_foreign

# dadbod: tunnel kube fake-ctx ns svc/pg $p_fail 5432
[t_fail]
host=localhost
port=$p_fail

# dadbod: tunnel kube bad;ctx ns svc/pg $p_bad 5432
[t_bad]
host=localhost
port=$p_bad

[plain]
host=localhost
# END dadbod
EOF
}
write_services 5432

fails=0
check() { # description, command
    if eval "$2"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); sed 's/^/     /' "$tmp/err" 2>/dev/null; fi
}
run() { "$@" >"$tmp/out" 2>"$tmp/err"; echo $? >"$tmp/code"; }
code() { cat "$tmp/code"; }
mainpid() { systemctl --user show -p MainPID --value "dbtunnel-$p_ok.service"; }

run "$here/pgro" -l
check "pgro -l flags, markers in any order" '[ "$(cat "$tmp/out")" = "t_ok (read-write) (tunnel)
t_foreign (read-write) (tunnel)
t_fail (tunnel)
t_bad (tunnel)
plain" ]'

run "$here/dbtunnel" up t_ok
check "up starts the tunnel" '[ "$(code)" = 0 ] && pg_isready -q -h localhost -p $p_ok'
pid=$(mainpid)
run "$here/dbtunnel" up t_ok
check "up reuses a healthy tunnel" '[ "$(code)" = 0 ] && [ "$(mainpid)" = "$pid" ] && [ ! -s "$tmp/err" ]'
run "$here/dbtunnel" status
check "status shows it up" 'grep -qE "^t_ok +$p_ok +up " "$tmp/out"'

write_services 5433
run "$here/dbtunnel" up t_ok
check "up restarts a tunnel with other settings" '[ "$(code)" = 0 ] && [ "$(mainpid)" != "$pid" ] && grep -q "other settings" "$tmp/err"'

socat "TCP-LISTEN:$p_foreign,bind=127.0.0.1,fork,reuseaddr" TCP:127.0.0.1:5432 &
foreign_pid=$!
sleep 0.5
run "$here/dbtunnel" up t_foreign
check "up refuses a port held by another process" '[ "$(code)" = 5 ] && grep -q "used by another process" "$tmp/err"'
run "$here/dbtunnel" status
check "status shows it foreign" 'grep -qE "^t_foreign +$p_foreign +foreign " "$tmp/out"'
run "$here/pgro" t_foreign "select 1"
check "pgro stops before connecting (exit 5)" '[ "$(code)" = 5 ]'

touch "$tmp/bin/fail"
run "$here/dbtunnel" up t_fail
check "failed start: exit 5 with the log tail" '[ "$(code)" = 5 ] && grep -q "could not start" "$tmp/err" && grep -q "fake failure" "$tmp/err"'
rm "$tmp/bin/fail"

touch "$tmp/bin/sso"
export DBTUNNEL_SSO_WAIT=4
run "$here/dbtunnel" up t_fail
check "expired SSO: login started, exit 5 with its URL" '[ "$(code)" = 5 ] && grep -q "not approved yet" "$tmp/err" && grep -q "device.example" "$tmp/err" && grep -q "shows code ABCD-1234" "$tmp/err"'
check "pending login does not hold the port lock" 'flock -n "$run_dir/port-$p_fail.lock" true'
run "$here/dbtunnel" up t_fail
check "a rerun shares the pending login" '[ "$(code)" = 5 ] && [ "$(pgrep -fc "$tmp/bin/aws sso login")" = 1 ]'
rm "$tmp/bin/sso"
unset DBTUNNEL_SSO_WAIT

run "$here/dbtunnel" up t_bad
check "invalid marker refused" '[ "$(code)" = 5 ] && grep -q "invalid context" "$tmp/err"'
run "$here/dbtunnel" up plain
check "service without tunnel refused" '[ "$(code)" = 5 ] && grep -q "has no tunnel" "$tmp/err"'
run "$here/dbtunnel" up mine
check "services outside the dadbod block ignored" '[ "$(code)" = 5 ]'

# reaping stops every idle tunnel, so only test it when no real tunnel is running
others=$(systemctl --user list-units --plain --no-legend --state=active 'dbtunnel-*.service' |
    awk '$1 ~ /^dbtunnel-[0-9]+\.service$/ && $1 != "dbtunnel-'$p_ok'.service"' | wc -l)
if [ "$others" = 0 ]; then
    rm -f "$run_dir/idle-$p_ok"
    run "$here/dbtunnel" reap
    check "first idle reap only marks the tunnel" '[ "$(systemctl --user is-active dbtunnel-$p_ok.service)" = active ] && [ -e "$run_dir/idle-$p_ok" ]'
    touch -d '-40 min' "$run_dir/idle-$p_ok"
    run "$here/dbtunnel" up t_ok
    check "a use clears the idle mark" '[ ! -e "$run_dir/idle-$p_ok" ]'
    "$here/dbtunnel" reap
    touch -d '-40 min' "$run_dir/idle-$p_ok"
    run "$here/dbtunnel" reap
    check "reap stops a tunnel idle for 30 min" '[ "$(systemctl --user is-active dbtunnel-$p_ok.service)" != active ]'
else
    echo "skip reap tests: other tunnels are running"
fi

run "$here/dbtunnel" up t_ok
run "$here/dbtunnel" down t_ok
check "down stops it" '[ "$(systemctl --user is-active dbtunnel-$p_ok.service)" != active ]'

echo
[ $fails -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
