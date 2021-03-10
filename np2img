#!/usr/bin/env python
import cv2
import numpy as np
import os
import sys
import getopt
from glob import glob

args, np_files = getopt.getopt(sys.argv[1:], '', ['ext=', 'name=', 'output-dir='])
args = dict(args)

# set defaults
args.setdefault('--ext', 'png')
if not np_files:
    np_files = '*.np*'  # default
if not isinstance(np_files, list):
    np_files = glob(np_files)
args.setdefault('--output-dir', os.path.dirname(np_files[0]))
key = args['--name']

# load images and save as jpg
for i, np_file in enumerate(np_files):
    print("\rLoading file {}/{} ...".format(i+1, len(np_files)), flush=True, end="")
    ext = os.path.splitext(np_file)[-1]
    if ext == '.npz':
        data = np.load(np_file)
        if key not in data:
            print("\n{} is not in the numpy archive. Please select one between:".format(key))
            keys = list(data.keys())
            for j, k in enumerate(keys):
                print("{}: {}".format(j, k))
            key = keys[int(input('choice: '))]
        image = data[key]
    elif ext == '.npy':
        image = np.load(np_file)
    else:
        print("Attention! Skipping non numpy archive file {}.".format(np_file), flush=True, end="")
        continue
    name = os.path.splitext(os.path.basename(np_file))[0]
    try:
        cv2.imwrite(os.path.join(args['--output-dir'], f"{name}.{args['--ext']}"), image)
    except:
        if args['--ext'] == 'npy':
            np.save(os.path.join(args['--output-dir'], f"{name}.{args['--ext']}"), image)
        elif args['--ext'] == 'npz':
            np.savez(os.path.join(args['--output-dir'], f"{name}.{args['--ext']}"), image)
        else:
            raise Exception("\n{} extension is not supported.".format(args['--ext']))

print("\nFinished.")
