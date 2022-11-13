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
import operator
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint
from datetime import timedelta

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

def parse_member_splits(race_obj, person, fixed_cp_points):
    member = Member()
    for r in race_obj['results']:
        if r['person_id'] == person['id']:
            member.bib = person['bib']
            print('{} '.format(member.bib), end='')
            for org in race_obj['teams']:
                #member.team_name = ""
                #member.team_bib = member.bib
                if org['id'] == person['team_id']:
                    member.team_name = org['name']
                    member.team_bib = org['number']
            member.first_name = person['name'].capitalize()
            member.last_name = person['surname'].capitalize()
            member.year_of_birth = person['year']
            member.points = r['scores']
            time = r['finish_msec'] - r['start_msec']
            if r['finish_msec'] < r['start_msec']:
                time = r['finish_msec'] + 86400000 - r['start_msec']
            member.time = timedelta(seconds=time/1000)
            member.penalty_time = timedelta(seconds=r['penalty_time']/1000)
            member.credit_time = timedelta(seconds=r['credit_time']/1000)

            prev_time = None
            for splt in r['splits']:
                cp = Checkpoint()
                cp.id = int(splt['code'])
                if cp.id is not None:
                    if fixed_cp_points > 0:
                        cp.points = fixed_cp_points
                    else:
                        cp.points = cp.id//10
                    #cp.split = timedelta(seconds=splt['leg_time']//1000)
                    cp.time = timedelta(seconds=splt['relative_time']//1000)
                    if prev_time is None:
                        cp.split = cp.time
                    else:
                        cp.split = cp.time - prev_time
                    prev_time = cp.time
                    member.sum += cp.points
                    member.route.append(cp)

            if len(member.route) < 1:
                return

            start = Startpoint()
            member.route.insert(0, start)

            finish = Finishpoint()
            nCps = len(member.route)
            for i in range(nCps):
                finish.split = member.time - (member.route[nCps - 1 - i].time if member.route[nCps - 1 - i].time is not None else member.time)
                if finish.split > timedelta():
                    finish.time = member.time
                    break
            member.route.append(finish)

            return member

def parse_sportorg_group(race_obj, group, fixed_cp_points):
    print('Parse splits for:', group['name'])
    teams = {}
    print('Parse splits for members: ', end='')
    for person in race_obj['persons']:
        if person['group_id'] == group['id']:
            member = parse_member_splits(race_obj, person, fixed_cp_points)
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
        team.res_time = member.time + member.penalty_time - member.credit_time
        team.penalty_time = member.penalty_time
        team.credit_time = member.credit_time
        team.route = member.route
        team.sum = member.sum
        team.group = group['name']
        team_name = team.members[0].team_name
        team.team_name = team_name
        for m in team.members:
            if m.team_name != team_name:
                team.team_name += ' - ' + m.team_name

        teams_list.append(team)

    teams_list.sort(reverse=False, key=operator.attrgetter('res_time'))
    teams_list.sort(reverse=True, key=operator.attrgetter('points'))

    for i in range(len(teams_list)):
        teams_list[i].place = i+1

    return teams_list

def parse_sportorg_result_json(json_filename):
    with open(json_filename) as json_file:
        sportorg_race_obj = json.load(json_file)['races'][0]
        event_title = sportorg_race_obj['data']['title'] + ' ' + sportorg_race_obj['data']['location']
        fixed_cp_points = -1
        if sportorg_race_obj['settings']['result_processing_mode'] == 'scores' and \
                sportorg_race_obj['settings']['result_processing_score_mode'] == 'fixed':
            fixed_cp_points = sportorg_race_obj['settings']['result_processing_fixed_score_value']
        teams = {}
        for group in sportorg_race_obj['groups']:
            group_name = group['name']
            duration = None
            match = re.search('\d{1,2}', group_name)
            if match:
                duration = match.group(0)
            print(group_name, duration)
            teams[group_name] = parse_sportorg_group(sportorg_race_obj, group, fixed_cp_points)
 
        return teams, event_title
