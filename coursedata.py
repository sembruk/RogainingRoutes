"""
   Copyright 2017 Semyon Yakimov
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
    csvreader = csv.reader(StringIO(data))
    for row in csvreader:
        print(row)
    

def parse_course_data_file(filename):
    with open(filename, newline='') as fd:
        data = fd.read()
    if is_IOF_course_data_xml_file(data):
        print('IOF XML parsing not implemented')
        return
    return parse_course_csv(data)


