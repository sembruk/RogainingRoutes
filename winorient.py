"""
   Copyright 2021 Semyon Yakimov
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
import math
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint, str_to_time
from datetime import timedelta
from lxml import html

def _debug(*args):
    #print(*args)
    pass

def parse_member_splits(line):
    wait = 'number'
    member = Member()
    member.team_name = ''
    member.group = None
    cp_time = None
    current_time = timedelta()
    _debug('===')
    for w in re.split('\s+', line):
        if w:
            if wait == 'number' and int(w):
                _debug('number', w)
                wait = 'surname'
            elif wait == 'surname':
                _debug('surname', w)
                member.last_name = w
                wait = 'name'
            elif wait == 'name':
                _debug('name', w)
                member.first_name = w
                wait = 'team'
            elif wait == 'team':
                try:
                    bib = int(w)
                    member.bib = bib
                    _debug('team_name', member.team_name)
                    _debug('bib', bib)
                    wait = 'year'
                    continue
                except ValueError:
                    if w in ('Iю','IIю','IIIю','I','II','III','КМС','МС','МСМК','ЗМС','б/р'):
                        continue
                    if member.team_name:
                        member.team_name += ' ' 
                    member.team_name += w
            elif wait == 'year':
                member.year_of_birth = int(w)
                _debug('year', w)
                wait = 'time'
            elif wait == 'time':
                try:
                    member.time = str_to_time(w)
                except Exception:
                    return 
                else:
                    wait = 'diff'
            elif wait == 'diff':
                wait = 'place'
            elif wait == 'place':
                if w != '=':
                    wait = 'cp'
            #        wait = 'group'
            #elif wait == 'group':
            #    _debug('group', w)
            #    member.group = w
            #    wait = 'cp'
            elif wait == 'cp':
                try:
                    code = int(w[:-1])
                    cp = Checkpoint()
                    cp.id = code
                    cp.points = cp.id//10
                    member.sum += cp.points
                    cp.split = cp_time
                    current_time += cp.split
                    cp.time = current_time
                    member.route.append(cp)
                except ValueError:
                    cp_time = str_to_time(w[:-1])
                _debug(w[:-1])
                
    start = Startpoint()
    member.route.insert(0, start)

    finish = Finishpoint()
    nCps = len(member.route)
    for i in range(nCps):
        finish.split = member.time - member.route[nCps - 1 - i].time
        if finish.split > timedelta():
            finish.time = member.time
            break
    member.route.append(finish)
    # FIXME
    member.points = member.sum

    return member

def parse_winorient_splits_html(splits_filename):
    tree = html.parse(splits_filename)
    root = tree.getroot()
    body = root.find('body')
    event_title = body.find('h1').text
    _debug(event_title)
    teams = dict()
    for h2 in body.iterfind('h2'):
        group_name = h2.text.split(',')[0]
        pre = h2.getnext()
        lines = pre.text_content()
        for l in lines.splitlines()[2:]:
            member = parse_member_splits(l)
            if member:
                member.group = group_name
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
        max_time = timedelta(hours=24)
        if team.points == team.sum and team.time > max_time:
            penalty = math.ceil((team.time - max_time).total_seconds()/60)
            team.points = team.sum - penalty

        if teams_by_group.get(team.group) is None:
            teams_by_group[team.group] = []
 
        teams_by_group[team.group].append(team)

    for _, teams_list in teams_by_group.items():
        teams_list.sort(reverse=False, key=operator.attrgetter('time'))
        teams_list.sort(reverse=True, key=operator.attrgetter('points'))

        for i in range(len(teams_list)):
            teams_list[i].place = i+1

    return teams_by_group, event_title

