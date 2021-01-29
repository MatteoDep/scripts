#!/usr/bin/env python
import cv2
import numpy as np
import os
import sys
import getopt
from glob import glob

args, npz_files = getopt.getopt(sys.argv[1:], '', ['format=', 'name=', 'output-dir='])
args = dict(args)

# set defaults
args.setdefault('--name', 'PiCamData')
args.setdefault('--format', 'png')
if not npz_files:
    npz_files = './data/*.npz'  # default
if not isinstance(npz_files, list):
    npz_files = glob(npz_files)
args.setdefault('--output-dir', os.path.dirname(npz_files[0]))
key = args['--name']

# load images and save as jpg
for i, npz_file in enumerate(npz_files):
    print("\rLoading file {}/{} ...".format(i+1, len(npz_files)), flush=True, end="")
    if os.path.splitext(npz_file)[-1] != '.npz':
        print("Attention! Skipping non npz file {}.".format(npz_file), flush=True, end="")
        continue
    data = np.load(npz_file)
    if key not in data:
        print("\n{} is not in the npz archive. Please select one between:".format(key))
        keys = data.keys()
        for j, k in enumerate(keys):
            print("{}: {}".format(j, k))
        key = keys[int(input('choice: '))]
    image = data[key]
    name = os.path.splitext(os.path.basename(npz_file))[0]
    cv2.imwrite(os.path.join(args['--output-dir'], f"{name}-{i+1}.{args['--format']}"), image)
print("\nFinished.")
