#!/usr/bin/env python
import cv2
import numpy as np
import os
import sys
import getopt
from glob import glob

args, npz_files = getopt.getopt(sys.argv[1:], '', ['name=', 'output-dir='])
args = dict(args)

# set defaults
args.setdefault('--name', 'PiCamData')
if not npz_files:
    npz_files = './data/*.npz'  # default
else:
    npz_files = npz_files[0]
args.setdefault('--output-dir', os.path.dirname(npz_files))
print(args['--name'])

# load images and save as jpg
npz_files = glob(npz_files)
images = []
for i, npz_file in enumerate(npz_files):
    print("\rLoading file {}/{} ...".format(i+1, len(npz_files)), flush=True, end="")
    if os.path.splitext(npz_file)[-1] != '.npz':
        print("Attention! Skipping non npz file {}.".format(npz_file), flush=True, end="")
        continue
    image = np.load(npz_file)[args['--name']]
    name = os.path.splitext(os.path.basename(npz_file))[0]
    cv2.imwrite(os.path.join(args['--output-dir'], f"{name}.jpg"), image)
print("\nFinished.")
