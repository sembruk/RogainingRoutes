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

import re
import operator
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint, str_to_time
from datetime import timedelta
from lxml import etree

sfr_spit_field_name = {
    'Номер': 'bib',
    'Фамилия': 'last_name',
    'Имя': 'first_name',
    'Фамилия, Имя': 'full_name',
    'Фамилия,': 'full_name',
    'Г.р.': 'year_of_birth',
    'Г.р': 'year_of_birth',
    'Команда': 'team_name',
    '***': 'points',
    'Итог': 'points',
    'Штраф': 'penalty',
    'Результат': 'time',
}

column_name = list()

def extract_event_title(title):
    return re.sub('[.,\s]+Протокол.+$', '', title)

def parse_member_splits(tr_element):
    member = Member()
    current_time = timedelta()
    i = 0
    for e in list(tr_element):
        text = e.text or e[0].text or ''
        tail = e[0][0].tail if len(e)>0 and len(e[0])>0 else ''
        tail = tail or ''
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
                    print('{} '.format(member.bib), end='')
                    match = re.match('\d+', text)
                    if match:
                        member.team_bib = int(match.group(0))
            elif text is not None:
                cp = Checkpoint()
                match = re.match('(\d+:\d+)\[(\d+)\]', text)
                if match:
                    cp_time = str_to_time(match.group(1))
                    cp.id = int(match.group(2))
                if cp.id is not None:
                    cp.points = cp.id//10
                    member.sum += cp.points
                    match = re.search('\d+:\d+$', tail)
                    if match:
                        cp.split = str_to_time(match.group(0))
                    else:
                        cp.split = cp_time
                    current_time += cp.split
                    cp.time = current_time

                    member.route.append(cp)
        i += 1

    if len(member.route) < 1:
        return

    member.time = str_to_time(member.time)
    if member.full_name:
        member.last_name, member.first_name = member.full_name.split(' ', 1)
    member.first_name = member.first_name.capitalize()
    member.last_name = member.last_name.capitalize()

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

    return member


def parse_SFR_splits_table(table_element, group):
    print('Parse splits for:', group)
    teams = dict()
    print('Parse splits for members: ', end='')
    for e in list(table_element):
        if e.tag == 'tr':
            member = parse_member_splits(e)
            if member:
                bib = member.team_bib
                if teams.get(bib) is None:
                    teams[bib] = Team()
                teams[bib].members.append(member)
    print('')
    teams_list = list()
    for bib in teams:
        team = teams[bib]
        nMembers = len(team.members)
        member = team.members[nMembers-1]
        team.bib = bib
        team.points = int(member.points)
        team.penalty = int(member.penalty) if member.penalty else 0
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

def parse_SFR_splits_html(splits_filename):
    parser = etree.HTMLParser()
    tree = etree.parse(splits_filename, parser)
    root = tree.getroot()
    body = root.find('body')
    event_title = body.find('h1').text
    event_title = extract_event_title(event_title)
    teams = dict()
    for e in list(body):
        if e.tag == 'h2':
            group = e.text
            duration = None
            match = re.search('\d{1,2}', group)
            if match:
                duration = match.group(0)
        elif e.tag == 'table':
            teams[group] = parse_SFR_splits_table(e, group)
    return teams, event_title

