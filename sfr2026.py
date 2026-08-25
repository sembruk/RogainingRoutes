"""
   Copyright 2026 Semyon Yakimov
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

import re
import operator
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint, str_to_time
from datetime import timedelta

sfr_spit_field_name = {
    'Номер': 'bib',
    'Фамилия': 'last_name',
    'Имя': 'first_name',
    'Фамилия, Имя': 'full_name',
    'Г.р.': 'year_of_birth',
    'Г.р': 'year_of_birth',
    'Команда': 'team_name',
    'Баллы': 'sum',
    'Штраф': 'penalty',
    'Итог': 'points',
    'Результат': 'time',
    'Место': 'place',
}

teams = dict()

def parse_row(row, group):
    team = Team()
    r = {}
    team.route = []
    prev_time = timedelta()
    sum = 0
    for k in row:
        text = row[k]
        if k in sfr_spit_field_name:
            r[sfr_spit_field_name[k]] = text
        elif k.startswith('#'):
            cp = Checkpoint()
            match = re.match('(\d+:\d+)\[(\d+)\]', text)
            if match:
                cp.id = int(match.group(2))
                cp.time = str_to_time(match.group(1))
            if cp.id is not None:
                cp.points = cp.id//10
                sum += cp.points
                cp.split = cp.time - prev_time
                prev_time = cp.time
                team.route.append(cp)

    team.team_name = r["team_name"].replace("<br>", " - ")
    team.bib = int(r["bib"])
    team.sum = int(r["sum"]) if r["sum"].isdigit() else sum
    team.points = int(r["points"])
    team.penalty = int(r["penalty"]) if r["penalty"].isdigit() else 0
    team.time = str_to_time(r["time"]) if r["time"] and r["time"][0].isdigit() else timedelta()
    team.group = group
    team.place = int(r["place"]) if r["place"].isdigit() else ''
    members = r["full_name"]
    members = members.replace("<br>", ", ")
    members = members.split(",")
    print(team.team_name)
    for m in members:
        member = Member()
        member.full_name = m.strip()
        if len(member.full_name.split()) == 1:
            continue
        member.last_name, member.first_name = member.full_name.split(' ', 1)
        member.first_name = member.first_name.capitalize()
        member.last_name = member.last_name.capitalize()
        team.members.append(member)

    start = Startpoint()
    start.time = timedelta()
    team.route.insert(0, start)

    finish = Finishpoint()
    nCps = len(team.route)
    for i in range(nCps):
        finish.split = team.time - team.route[nCps - 1 - i].time
        if finish.split > timedelta():
            finish.time = team.time
            break
    team.route.append(finish)

    if not group in teams:
        teams[group] = []
    teams[group].append(team)

def parse_SFR_splits2026_html(splits_filename):
    html = open(splits_filename, encoding='utf-8').read()

    match = re.search(r'const\s+db\s*=\s*"((?:\\.|[^"\\])*)"', html)

    if not match:
        raise ValueError('const db not found')

    db = match.group(1)

    parts = db.split('|')

    header_positions = [i for i, value in enumerate(parts) if value.strip() == 'п/п']

    parts = db.split('|')

    for group_index, header_pos in enumerate(header_positions):
        group = None

        for i in range(header_pos - 1, -1, -1):
            value = parts[i].strip()

            if value:
                group = value
                print(group)
                break

        group_end = (
            header_positions[group_index + 1]
            if group_index + 1 < len(header_positions)
            else len(parts)
        )

        last_header = None

        for i in range(header_pos, group_end):
            value = parts[i].strip()

            if value == '':
                last_header = i
                break

        if last_header is None:
            continue

        headers = parts[header_pos:last_header + 1]

        column_count = len(headers)

        data_start = last_header + 1

        for pos in range(
            data_start,
            group_end,
            column_count
        ):
            values = parts[pos:pos + column_count]

            if len(values) < column_count:
                break

            if not values[0].strip().isdigit():
                continue

            row = dict(zip(headers, values))
            parse_row(row, group)

    return teams, ''

