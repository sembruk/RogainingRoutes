"""
   Copyright 2024 Semyon Yakimov
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
from lxml import html

def _debug(*args):
    print(*args)
    #pass

def parse_split_line(line):
    match = re.match(r'(\d+)\s+\(\s*(\d+)\)\s+(\d{2}:\d{2}:\d{2})\s+(\d{2}:\d{2}:\d{2})\s+(\d+)', line)
    if match:
        return {
            "index": match.group(1),
            "cp_code": match.group(2),
            "time": match.group(3),
            "split_time": match.group(4),
            "points": int(match.group(5))
        }
    return None

def parse_winorient_printout_html(html_filename):
    with open(html_filename, encoding='cp1251') as f:
        html_content = f.read()
        tree = html.fromstring(html_content)
        pre_tags = tree.xpath('//pre')

        teams = dict()

        for pre_tag in pre_tags:
            text_lines = pre_tag.text_content().strip().splitlines()
            for i, line in enumerate(text_lines):
                line = line.strip()

                # Extract participant number and team name
                if line.startswith('№') and text_lines[i+1].startswith('Коллектив'):
                    member = Member()
                    current_time = timedelta()
                    member.bib = int(line.split()[1].rstrip(','))
                    member.last_name = line.split()[2].strip()
                    member.first_name = line.split()[3].strip()
                    member.team_name = text_lines[i+1].split(':', 1)[-1].strip()[3:]
                    member.points = None
                    member.group = ''

                # Parse the control point data
                elif line and line[0].isdigit():
                    split_data = parse_split_line(line)
                    if not split_data:
                        continue
                    cp = Checkpoint()
                    cp.id = int(split_data['cp_code'])
                    cp.points = split_data['points']
                    member.sum += cp.points
                    cp.split = str_to_time(split_data['split_time'])
                    current_time += cp.split
                    cp.time = current_time
                    member.route.append(cp)
                    #_debug('cp', cp.id, cp.time)

                elif line.startswith('Финиш'):
                    start = Startpoint()
                    member.route.insert(0, start)

                    finish = Finishpoint()
                    finish.split = str_to_time(line.split()[2])
                    member.route.append(finish)

                # Extract total time and total score
                elif line.startswith('Результат'):
                    result_parts = line.split(',')
                    time_str = result_parts[0].split()[-1].lstrip(':')
                    member.time = str_to_time(time_str)
                    member.points = int(result_parts[1].split(':')[-1].strip())
                    bib = member.bib%1000
                    if teams.get(bib) is None:
                        teams[bib] = Team()
                    teams[bib].members.append(member)

        teams_by_group = {}
        for bib in teams:
            team = teams[bib]
            nMembers = len(team.members)
            member = team.members[nMembers-1]
            team.bib = bib
            team.points = int(member.points)
            team.time = member.time
            team.sum = member.sum
            team_name = team.members[0].team_name
            team.team_name = team_name
            for m in team.members:
                if int(m.points) < team.points:
                    team.points = int(m.points)
                if m.time > team.time:
                    team.time = m.time
                if m.sum < team.sum:
                    team.sum = m.sum
                if m.team_name != team_name:
                    team.team_name += ' - ' + m.team_name
            team.route = member.route
            team.group = member.group

            # FIXME
            #max_time = timedelta(hours=3)
            #if team.points == team.sum and team.time > max_time:
            #    penalty = math.ceil((team.time - max_time).total_seconds()/60)
            #    team.points = team.sum - penalty

            if teams_by_group.get(team.group) is None:
                teams_by_group[team.group] = []
     
            teams_by_group[team.group].append(team)

        for _, teams_list in teams_by_group.items():
            teams_list.sort(reverse=False, key=operator.attrgetter('time'))
            teams_list.sort(reverse=True, key=operator.attrgetter('points'))

            for i in range(len(teams_list)):
                teams_list[i].place = i+1

        #FIXME
        event_title = 'Рогейн Окская тропа 8 часа'
        return teams_by_group, event_title






