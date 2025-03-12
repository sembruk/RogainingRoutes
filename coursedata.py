"""
   Copyright 2017-2022 Semyon Yakimov
   This file is part of RogainingRoutes.
   RogainingRoutes is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   RogainingRoutes is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   You should have received a copy of the GNU General Public License
   along with RogainingRoutes.  If not, see <http://www.gnu.org/licenses/>.
"""

from io import StringIO
import csv
import gpxpy
import utm
import xml.etree.ElementTree as ET

def is_IOF_course_data_xml_file(data):
    try:
        tree = ET.fromstring(data)
        root = tree.getroot()
        if root.tag == 'CourseData' and root.find('IOFVersion'):
            return True
    except ET.ParseError:
        pass
    return False

def parse_course_csv(data):
    cps = dict()
    csvreader = csv.reader(StringIO(data))
    for row in csvreader:
        code = row[0]
        if code == 'rotate_angle':
            cps[code] = float(row[1])
            continue
        if code.isdigit():
            code = int(code)
        x = int(float(row[1]))
        y = int(float(row[2]))
        cps[code] = (x, y)
    return cps

def parse_course_gpx_file(filename):
    with open(filename, encoding='utf-8-sig') as gpx_file:
        cps = dict()
        gpx = gpxpy.parse(gpx_file)
        for wpt in gpx.waypoints:
            code = wpt.name
            if code.isdigit():
                code = int(code)
            else:
                code = code.lower()
            utm_coords = utm.from_latlon(wpt.latitude, wpt.longitude)
            x = int(utm_coords[0])
            y = int(utm_coords[1])
            cps[code] = (x, y)
        return cps

def parse_course_data_file(filename):
    if filename.lower().endswith('.gpx'):
        return parse_course_gpx_file(filename)
    with open(filename, newline='') as fd:
        data = fd.read()
    if is_IOF_course_data_xml_file(data):
        print('IOF XML parsing not implemented')
        return
    return parse_course_csv(data)


