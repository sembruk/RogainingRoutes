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
import math
import shutil
from jinja2 import Template
import sfr
import coursedata


map_dpi = 72
map_scale_factor = 15000
start_x = 251
start_y = 654
javascript_map_scale = 1


meters_in_pixel = map_scale_factor * 0.0254 / map_dpi

def make_team_html(team, event_title, cp_coords):
    team.full_name = team.get_team_full_name()
    title = '{} | {}'.format(team.full_name, event_title)
    team.penalty = team.sum - team.points
    if team.penalty < 0:
        team.penalty = 0
    table_titles = [
        'КП',
        'Время',
        'Сплит',
        'Очки',
        'Расстояние, км',
        'Темп, мин/км',
        'Мин/очко'
    ]

    cp_list = []
    data = []
    total_points = 0
    previos = [start_x, start_y]
    total_distance = 0

    for i in range(len(team.route)):
        cp = team.route[i]
        x = start_x
        y = start_y
        if isinstance(cp.id, int):
            x += int(cp_coords[cp.id][0]/meters_in_pixel)
            y += int(cp_coords[cp.id][1]/meters_in_pixel)
        cp_list.append([x, y])

        total_points += cp.points

        leg_distance = math.sqrt((x - previos[0])**2 + (y - previos[1])**2)
        leg_distance /= 1000 # km
        total_distance += leg_distance

        previos[0] = x
        previos[1] = y

        pace = 0
        if cp.split:
            pace = cp.split.total_seconds()/leg_distance/60

        minToPoints = 0
        if cp.points:
            minToPoints = cp.split.total_seconds()/cp.points/60

        d = [
            i,
            cp.id,
            cp.time or '',
            cp.split or '',
            '{} / {}'.format(cp.points, total_points) if cp.points > 0 else '',
            '{:.2f} / {:.2f}'.format(leg_distance, total_distance) if leg_distance > 0 else '',
            '{:.2f}'.format(pace) if pace else '',
            '{:.2f}'.format(minToPoints) if minToPoints else ''
        ]
        data.append(d)

    html = open('templates/team.html').read()
    template = Template(html)
    with open(os.path.join(output_dir, team.get_team_html_name()), 'w') as fd:
        fd.write(template.render(title=title, team=team, table_titles=table_titles, map_scale=javascript_map_scale, cp_list=cp_list, data=data))


def make_result_html(teams, event_title, cp_coords):
    print('Make result HTML')

    table_titles = [
        'Место',
        'Команда',
        'Участники',
        'Результат',
        'Время'
    ]

    group_list = sorted(teams)
    data = {}
    for group in teams:
        data[group] = [];
        for team in teams[group]:
            make_team_html(team, event_title, cp_coords)
            t = [
                team.place,
                '<a href="{}">{}</a>'.format(team.get_team_html_name(), team.get_team_full_name()),
                team.get_members_str(),
                team.points,
                team.time
            ]
            data[group].append(t)

    html = open('templates/results.html').read()
    template = Template(html)
    with open(os.path.join(output_dir, 'results.html'), 'w') as fd:
        fd.write(template.render(title=event_title, table_titles=table_titles, group_list=group_list, data=data))


input_dir = 'input'
output_dir = 'output'

teams, event_title = sfr.parse_SFR_splits_html(os.path.join(input_dir, 'splits.htm'))
cp_coords = coursedata.parse_course_data_file(os.path.join(input_dir, 'coords.csv'))

shutil.rmtree(output_dir, ignore_errors=True)
os.mkdir(output_dir)
shutil.copy(os.path.join(input_dir, 'map.jpg'), os.path.join(output_dir, 'map.jpg'))

make_result_html(teams, event_title, cp_coords)


