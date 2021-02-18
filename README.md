# RogainingRoutes

![](/example/screenshot.jpg?raw=true)

Display rogainers routes on the competition map.

[Example](https://forestadventure.ru/files/2020/fa/routes.html)

## Usage

```
./rogainingroutes [-h] [-c COORDS_FILE] [-m MAP_FILE] [-d MAP_DPI] [-l MAP_SCALE]
                       [-o OUTPUT_DIR]
                       [file]

Command line utility to generate routes.

positional arguments:
  file                  splits SFR HTML file (default: splits.html)

optional arguments:
  -h, --help            show this help message and exit
  -c COORDS_FILE, --coords-file COORDS_FILE
                        coords CSV file (default: coords.csv)
  -m MAP_FILE, --map-file MAP_FILE
                        map file (default: map.jpg)
  -d MAP_DPI, --map-dpi MAP_DPI
                        map DPI (default: 72)
  -l MAP_SCALE, --map-scale MAP_SCALE
                        map scale (default: 25000)
  -o OUTPUT_DIR, --output-dir OUTPUT_DIR
                        output directory (default: output)
```

