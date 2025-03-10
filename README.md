# RogainingRoutes

![](/example/screenshot.jpg?raw=true)

Display rogainers routes on the competition map.

[Example](https://forestadventure.ru/files/2020/fa/routes.html)

## Installation

```
pip install -r requirements.txt
```

## Usage

```
python ./rogainingroutes [-h] [-c COORDS_FILE] [-m MAP_FILE] -x START_X -y START_Y [-d MAP_DPI] [-l MAP_SCALE] [-a ANGLE]
                       [-o OUTPUT_DIR]
                       [file]

Command line utility to generate routes.

positional arguments:
  file                  results file: SportOrg JSON, CSV, WinOrient or SFR splits HTML (default: splits.html)

options:
  -h, --help            show this help message and exit
  -c COORDS_FILE, --coords-file COORDS_FILE
                        coords GPX or CSV file (default: coords.csv)
  -m MAP_FILE, --map-file MAP_FILE
                        map file (default: map.jpg)
  -x START_X, --start-x START_X
                        start X offset in pixels of the map (default: None)
  -y START_Y, --start-y START_Y
                        start Y offset in pixels of the map (default: None)
  -d MAP_DPI, --map-dpi MAP_DPI
                        map DPI (default: 72)
  -l MAP_SCALE, --map-scale MAP_SCALE
                        map scale (default: 25000)
  -a ANGLE, --angle ANGLE
                        map rotate angle (default: 0.0)
  -o OUTPUT_DIR, --output-dir OUTPUT_DIR
                        output directory (default: output)
  --hide-team-name
```

