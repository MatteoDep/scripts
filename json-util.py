#!/bin/env python
import json
import os
import sys

# Define options
# Note: keep help as last element
options = [
        ['-c', '--compress', 'remove all tabs and new lines to save disk space.'],
        ['-e', '--expand', 'expand in a more human readable format with indentation.'],
        ['-h', '--help', 'display this message.']
        ]
options_flat = [o for opt in options for o in opt[:2]]
help_msg = "Usage: json-util --command /path/to/json_file.json [/path/to/json_file2.json [etc]]\nopt:\n"
for opt in options:
    help_msg += '{} {}:\n\t{}\n'.format(*opt)

# check if opt is help
opt = sys.argv[1]
if opt in options[-1]:
    print(help_msg)
    sys.exit()

# check correct usage
assert opt in options_flat, help_msg
assert len(sys.argv) > 2, help_msg

# run through inputs
paths = sys.argv[1:]
if not os.path.exists(paths[0]):
    from glob import glob
    paths = [p for ps in [glob(p) for p in paths] for p in ps]
for path in paths:
    path = os.path.expanduser(path)
    print("path:", path)
    content = json.load(open(path))
    if opt in options[0][:2]:
        print(json.dumps(content))
    if opt in options[1][:2]:
        print(json.dumps(content, indent=4))

pass
