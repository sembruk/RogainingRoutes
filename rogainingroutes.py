#!/usr/bin/env python3
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

import os
import shutil
from jinja2 import Template
import sfr
import coursedata

javascript_map_scale = 1
start_x = 500
start_y = 500

def make_team_html(team):
    title = '{}. {}'.format(team.bib, team.get_team_name())
    team.full_name = team.get_team_name()
    team.pos = -1
    team.penalty = -1
    team.sum = -1
    table_titles = [
        'КП',
        'Время',
        'Сплит',
        'Очки',
        'Расстояние, км',
        'Скорость, км/ч',
        'Темп, мин/км',
        'Мин/очко'
    ]

    html = open('templates/team.html').read()
    template = Template(html)
    with open(os.path.join(output_dir, team.get_team_html_name()), 'w') as fd:
        fd.write(template.render(title=title, team=team, table_titles=table_titles, map_scale=javascript_map_scale))


def make_result_html(teams, event_title):
    print('Make result HTML')

    data = dict()
    for group in teams:
        data[group] = [];
        for team in teams[group]:
            make_team_html(team)
            t = [team.bib,
                 '<a href="{}">{}</a>'.format(team.get_team_html_name(), team.get_team_name()),
                 team.get_members_str(),
                 team.points,
                 team.time
                ]
            data[group].append(t)

    html = open('templates/results.html').read()
    template = Template(html)
    with open(os.path.join(output_dir, 'results.html'), 'w') as fd:
        fd.write(template.render(title=event_title, data=data))


input_dir = 'input'
output_dir = 'output'

teams, event_title = sfr.parse_SFR_splits_html(os.path.join(input_dir, 'splits.htm'))
cps = coursedata.parse_course_data_file(os.path.join(input_dir, 'coords.csv'))

shutil.rmtree(output_dir, ignore_errors=True)
os.mkdir(output_dir)
shutil.copy(os.path.join(input_dir, 'map.jpg'), os.path.join(output_dir, 'map.jpg'))

make_result_html(teams, event_title)


