#!/bin/env python
import json
import os
import sys

help_msg = "Usage: format-json /path/to/json_file.json"

assert len(sys.argv) > 1, help_msg

for path in sys.argv[1:]:
    path = os.path.expanduser(path)
    content = json.load(open(path))
    with open(path, 'w') as f:
        json.dump(content, f, indent=4)
