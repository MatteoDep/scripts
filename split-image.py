import sys
import os
import cv2
import getopt

if __name__ == '__main__':
    args, image_path = getopt.getopt(sys.argv[1:], '', ['rangex=', 'rangey=', 'grid='])
    args = dict(args)

    # set defaults
    args.setdefault('--rangex', '')
    args.setdefault('--rangey', '')
    args.setdefault('--grid', '4,6')
    image_path = image_path[0]
    if not image_path:
        print("Please specify input image")
    else:
        image = cv2.imread(image_path)
        h, w = image.shape[:2]
        rangex = [int(a) for i, a in enumerate(args['--rangex'].split(',')) if a]
        rangey = [int(a) for i, a in enumerate(args['--rangey'].split(',')) if a]
        if len(rangex)==0:
            rangex = [0, w]
        if len(rangey)==0:
            rangey = [0, h]
        grid = [int(a) for a in args['--grid'].split(',')]
        image = image[rangey[0]:rangey[1], rangex[0]:rangex[1], :]
        h, w = image.shape[:2]
        delta_y = int(h/grid[0])
        delta_x = int(w/grid[1])
        for i in range(grid[0]):
            for j in range(grid[1]):
                # print('{}:{}'.format(i*delta_y, min(h, (i+1)*delta_y)), '\n{}:{}'.format(j*delta_x, min(w, (j+1)*delta_x)), '\n')
                cut_image = image[i*delta_y:min(h, (i+1)*delta_y), j*delta_x:min(w, (j+1)*delta_x), :]
                name, ext = os.path.splitext(image_path)
                cv2.imwrite(name + '_{}-{}'.format(i+1, j+1) + ext, cut_image)


