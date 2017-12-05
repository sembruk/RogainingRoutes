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

sfr_spit_field_name_by_index = (
    'number',
    'bib',
    'last_name',
    'first_name',
    'year_of_birth',
    'team_name',
    'points',
    'time',
    '_'
)

import re
from lxml import etree

def extract_event_title(title):
    return re.sub('\s+Протокол.+$', '', title)

def parse_member_splits(tr_element):
    member = dict()
    i = 0
    for e in list(tr_element):
        if e.tag == 'td':
            text = e.text or e[0].text
            if i < len(sfr_spit_field_name_by_index):
                print(text)
                member[sfr_spit_field_name_by_index[i]] = text
            #else:
            #TODO
        i += 1
    print(member)

def parse_SFR_splits_table(table_element, group):
    print('Parse splits for:', group)
    for e in list(table_element):
        if e.tag == 'tr' and e[0].tag != 'th':
            parse_member_splits(e)

def parse_SFR_splits_html(splits_filename):
    parser = etree.HTMLParser()
    tree = etree.parse(splits_filename, parser)
    root = tree.getroot()
    body = root.find('body')
    event_title = body.find('h1').text
    event_title = extract_event_title(event_title)
    for e in list(body):
        if e.tag == 'h2':
            group = e.text
            duration = None
            match = re.search('\d{1,2}', group)
            if match:
                duration = match.group(0)
        elif e.tag == 'table':
            parse_SFR_splits_table(e, group)

    
parse_SFR_splits_html('in/splits.htm')

