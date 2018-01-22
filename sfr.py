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
from member import Member
from datetime import timedelta
from lxml import etree

class Team:
    def __init__(self):
        self.members = []
        self.names = []

    def get_team_name(self):
        return ' - '.join(self.names)

    def get_members_str(self):
        return ", ".join(["%s" % m for m in self.members])


sfr_spit_field_name = {
    'Номер': 'bib',
    'Фамилия': 'last_name',
    'Имя': 'first_name',
    'Г.р.': 'year_of_birth',
    'Команда': 'team_name',
    '***': 'points',
    'Результат': 'time',
}

column_name = list()

def str_to_time(s):
    match = re.match('(\d*):{,1}(\d{1,2}):(\d\d)',s)
    if match:
        h = int(match.group(1) or 0)
        m = int(match.group(2))
        s = int(match.group(3))
        return timedelta(hours=h, minutes=m, seconds=s)

def extract_event_title(title):
    return re.sub('\s+Протокол.+$', '', title)

def parse_member_splits(tr_element):
    member = Member()
    #member['route'] = list()
    current_time = timedelta()
    i = 0
    for e in list(tr_element):
        text = e.text or e[0].text
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
                cp = {}
                match = re.match('(\d+:\d+)\[(\d+)\]', text)
                if match:
                    cp_time = str_to_time(match.group(1))
                    cp['id'] = int(match.group(2))
                if cp.get('id') is not None:
                    match = re.search('\d+:\d+$', text)
                    if match:
                        cp['split'] = str_to_time(match.group(0))
                    else:
                        cp['split'] = cp_time
                    current_time += cp['split']
                    cp['time'] = current_time

                    member.route.append(cp)
        i += 1

    if len(member.route) < 1:
        return

    member.time = str_to_time(member.time)

    finish = dict()
    nCps = len(member.route)
    for i in range(nCps):
        finish['split'] = member.time - member.route[nCps - i - 1]['time']
        if finish['split'] > timedelta():
            break
    member.route.append(finish)
    return member

def insertByResult(l, team):
    if len(l) < 1:
        l.append(team)
        return
    for i in range(len(l)):
        if team.points > l[i].points:
            l.insert(i, team)
            break
        elif team.points == l[i].points:
            if team.time < l[i].time:
                l.insert(i, team)
                break
        if i == len(l):
            l.append(team)
            break

def parse_SFR_splits_table(table_element, group):
    print('Parse splits for:', group)
    teams_unsort = dict()
    print('Parse splits for members: ', end='')
    for e in list(table_element):
        if e.tag == 'tr':
            member = parse_member_splits(e)
            if member:
                bib = member.team_bib
                if teams_unsort.get(bib) is None:
                    teams_unsort[bib] = Team()
                teams_unsort[bib].members.append(member)
    print('')
    teams = list()
    for bib in teams_unsort:
        team = teams_unsort[bib]
        nMembers = len(team.members)
        member = team.members[nMembers-1]
        team.bib = bib
        team.points = int(member.points)
        team.time = member.time
        team.route = member.route
        team.group = group
        team.names.append(team.members[0].team_name)
        for m in team.members:
            if m.team_name != team.names[0]:
                team.names.append(m.team_name)

        insertByResult(teams, team)
    return teams

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

