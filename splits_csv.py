"""
   Copyright 2020 Semyon Yakimov
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

import csv
import re
import operator
from io import StringIO
from datetime import timedelta
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint

first_cp_column = 12
skip_first_row = True

fields_order = {
    'surname_name': 1,
    'group': 4,
    'team_name': 5,
    'bib': 6,
    'points': 7,
    'penalty': 8,
    'total_points': 9,
    'start_time': 10,
    'finish_time': 11,
    #'time': 9
}

def str_to_time(s):
    match = re.match('(\d+):(\d\d):(\d\d)',s)

    if not match:
        match = re.match('()(\d+):(\d\d)',s)

    if match:
        h = int(match.group(1) or 0)
        m = int(match.group(2))
        s = int(match.group(3))
        return timedelta(hours=h, minutes=m, seconds=s)
    else:
        raise Exception(s)

def parse_teams(csv_filename):
    with open(csv_filename, newline='') as fd:
        data = fd.read()
        csvreader = csv.reader(StringIO(data), delimiter=';')
        teams = {}
        event_title = ''
        if skip_first_row:
            next(csvreader)
        for row in csvreader:
            if row[0] == 'event_title':
                event_title = row[1]
                continue
            member = Member()
            if len(row) >= first_cp_column:
                surname_name = row[fields_order['surname_name']]
                member.last_name = surname_name.split()[0].title()
                member.first_name = surname_name.split()[-1].title()
                member.bib = row[fields_order['bib']]
                print(member.bib, member.first_name, member.last_name)
                member.team_bib = member.bib
                member.group = row[fields_order['group']]
                member.team_name = row[fields_order['team_name']] if row[fields_order['team_name']] else ''
                member.sum = int(row[fields_order['points']])
                member.penalty = int(row[fields_order['penalty']])
                member.points = int(row[fields_order['total_points']])
                try:
                    member.time = str_to_time(row[fields_order['finish_time']])
                except:
                    continue

                start_time = str_to_time(row[fields_order['start_time']])
                prev_time = timedelta()
                for i in range(first_cp_column, len(row), 2):
                    cp = Checkpoint()
                    cp.id = row[i]
                    if cp.id:
                        cp.id = int(cp.id)
                        cp.points = cp.id//10
                        abs_time = prev_time
                        if row[i + 1]:
                            abs_time = str_to_time(row[i + 1])
                        cp.split = abs_time - prev_time
                        prev_time = abs_time
                        cp.time = abs_time # - start_time
                        #member.sum += cp.points
                        member.route.append(cp)
                        print(cp.id, cp.time, cp.split)

                if len(member.route) < 1:
                    return

                start = Startpoint()
                member.route.insert(0, start)

                finish = Finishpoint()
                finish.time = member.time
                nCps = len(member.route)
                for i in range(nCps):
                    finish.split = member.time - member.route[nCps - 1 - i].time
                    if finish.split > timedelta():
                        break
                member.route.append(finish)

                bib = member.team_bib
                if bib not in teams:
                    teams[bib] = Team()
                teams[bib].members.append(member)
        return teams, event_title

def parse_splits_csv(csv_filename):
    teams,event_title = parse_teams(csv_filename)
    #teams_list = []
    teams_groups = {}
    for bib in teams:
        team = teams[bib]
        nMembers = len(team.members)
        member = team.members[nMembers-1]
        team.bib = bib
        team.group = member.group
        team.points = int(member.points)
        team.penalty = int(member.penalty) if member.penalty else 0
        team.time = member.time
        team.route = member.route
        team.sum = member.sum
        team_name = member.team_name
        team.team_name = team_name
        for m in team.members:
            if m.team_name != team_name:
                team.team_name += ' - ' + m.team_name

        if team.group not in teams_groups:
            teams_groups[team.group] = []
        teams_groups[team.group].append(team)

    for teams_list in teams_groups.values():
        teams_list.sort(reverse=False, key=operator.attrgetter('time'))
        teams_list.sort(reverse=True, key=operator.attrgetter('points'))

        for i in range(len(teams_list)):
            teams_list[i].place = i+1

    return teams_groups, event_title



 

