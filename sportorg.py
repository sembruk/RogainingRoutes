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

import re
import json
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint
from datetime import timedelta

def parse_member_splits(race_obj, person):
    member = Member()
    for r in race_obj['results']:
        if r['person_id'] == person['id']:
            pass

def parse_sportorg_group(race_obj, group):
    print('Parse splits for:', group['name'])
    teams = {}
    print('Parse splits for members: ', end='')
    for person in race_obj['persons']:
        if person['group_id'] == group['id']:
            member = parse_member_splits(person)
            if member:
                bib = member.team_bib
                if bib not in teams:
                    teams[bib] = Team()
                teams[bib].members.append(member)
    print('')
    teams_list = []
    for bib in teams:
        team = teams[bib]
        nMembers = len(team.members)
        member = team.members[nMembers-1]
        team.bib = bib
        team.points = int(member.points)
        team.time = member.time
        team.route = member.route
        team.sum = member.sum
        team.group = group
        team_name = team.members[0].team_name
        team.team_name = team_name
        for m in team.members:
            if m.team_name != team_name:
                team.team_name += ' - ' + m.team_name

        teams_list.append(team)

    teams_list.sort(reverse=False, key=operator.attrgetter('time'))
    teams_list.sort(reverse=True, key=operator.attrgetter('points'))

    for i in range(len(teams_list)):
        teams_list[i].place = i+1

    return teams_list

def parse_sportorg_result_json(json_filename):
    with open(json_filename) as json_file:
        sportorg_race_obj = json.load(json_file)
        event_title = sportorg_race_obj['data']['title']
        teams = {}
        for group in sportorg_race_obj['groups']:
            group_name = group['name']
            duration = None
            match = re.search('\d{1,2}', group_name)
            if match:
                duration = match.group(0)
            print(group_name, duration)
            teams[group_name] = parse_sportorg_group(sportorg_race_obj, group)
 
        return teams, event_title
