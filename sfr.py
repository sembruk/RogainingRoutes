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

sfr_spit_field_name = {
    'Номер': 'bib',
    'Фамилия': 'last_name',
    'Имя': 'first_name',
    'Г.р.': 'year_of_birth',
    'Команда': 'team_name',
    '***': 'points',
    'Результат': 'time',
}

column_name = list()

import re
from datetime import timedelta
from lxml import etree

def extract_event_title(title):
    return re.sub('\s+Протокол.+$', '', title)

def parse_member_splits(tr_element):
    member = dict()
    i = 0
    for e in list(tr_element):
        text = e.text or e[0].text
        if e.tag == 'th':
            if i == 0:
                column_name.clear()
            match = re.match('\S+', text)
            if match:
                text = match.group(0)
            column_name.append(text)
        elif e.tag == 'td':
            if (i < len(column_name)
                    and sfr_spit_field_name.get(column_name[i])):
                key = sfr_spit_field_name[column_name[i]]
                member[key] = text
                if key == 'bib':
                    match = re.match('\d+', text)
                    if match:
                        member['team_bib'] = int(match.group(0))
            elif text is not None:
                cp = {}
                match = re.match('(\d+):(\d+)\[(\d+)\]', text)
                if match:
                    cp['time'] = timedelta(minutes=int(match.group(1)), seconds=int(match.group(2)))
                    cp['id'] = int(match.group(3))
        i += 1

def parse_SFR_splits_table(table_element, group):
    print('Parse splits for:', group)
    for e in list(table_element):
        if e.tag == 'tr':
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

