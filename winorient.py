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
    print(*args)
    #pass

table_header_dict = {
    '№п/п': 'number',
    'Фамилия,': 'surname',
    'имя': 'name',
    'Коллектив': 'team',
    'Номер': 'bib',
    'ГР': 'year',
    'Очки': 'sum',
    'Штраф': 'penalty',
    'Итого': 'score',
    'Результат': 'time',
    'Отставание': 'diff',
    'Группа': 'group',
}

table_columns = []

def parse_table_header(line):
    table_columns.clear()
    for w in re.split('\s+', line):
        if w in table_header_dict:
            table_columns.append(table_header_dict[w])
    _debug(table_columns)

def parse_member_splits(line):
    member = Member()
    member.team_name = ''
    member.points = None
    member.group = None
    member.penalty = None
    cp_time = None
    current_time = timedelta()
    if not line:
        return
    _debug('===')
    i = -1
    for w in re.split('\s+', line):
        if w:
            i += 1
            if i >= len(table_columns):
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
                    _debug('cp', cp.id, cp.time)
                except ValueError:
                    cp_time = str_to_time(w[:-1])
            elif table_columns[i] == 'number':
                _debug('number', w)
            elif table_columns[i] == 'surname':
                _debug('surname', w)
                member.last_name = w
            elif table_columns[i] == 'name':
                _debug('name', w)
                member.first_name = w
            elif table_columns[i] == 'team':
                member.team_name += w
            elif table_columns[i] == 'bib':
                try:
                    bib = int(w)
                    member.bib = bib
                    _debug('team_name', member.team_name)
                    _debug('bib', bib)
                except ValueError:
                    i -= 1
                    if w in ('Iю','IIю','IIIю','I','II','III','КМС','МС','МСМК','ЗМС','б/р'):
                        continue
                    member.team_name += ' ' + w
            elif table_columns[i] == 'sum':
                _debug('sum', w)
            elif table_columns[i] == 'penalty':
                _debug('penalty', w)
                member.penalty = int(re.search(r'\d+', w).group())
            elif table_columns[i] == 'score':
                _debug('score', w)
                member.points = int(w)
            elif table_columns[i] == 'year':
                member.year_of_birth = int(w)
                _debug('year', w)
            elif table_columns[i] == 'time':
                try:
                   member.time = str_to_time(w)
                   _debug('time', w)
                except Exception:
                    return 
            elif table_columns[i] == 'group':
                _debug('group', w)
                member.group = w

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
    if member.points is None:
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
        parse_table_header(lines.splitlines()[0])
        for l in lines.splitlines()[1:]:
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
        team.penalty = member.penalty if member.penalty else 0
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

    return teams_by_group, event_title

