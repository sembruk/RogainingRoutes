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

from datetime import timedelta

class Member:
    def __init__(self):
        self.route = []
        self.sum = 0

    def __setitem__(self, key, value):
        setattr(self, key, value)

    def get_full_name(self):
        return self.first_name + ' ' + self.last_name

    def __str__(self):
        return self.get_full_name()


class Team:
    def __init__(self):
        self.members = []
        self.names = []

    def get_team_name(self):
        return ' - '.join(self.names)

    def get_team_full_name(self):
        return '{} {}'.format(self.bib, self.get_team_name())

    def get_team_html_name(self):
        return 'team{}.html'.format(self.bib)

    def get_members_str(self):
        return ", ".join(["%s" % m for m in self.members])


class Checkpoint:
    def __init__(self):
        self.id = None
        self.points = 0
        self.split = timedelta()
        self.time = timedelta()

class Startpoint(Checkpoint):
    def __init__(self):
        Checkpoint.__init__(self)
        self.id = 'S'

class Finishpoint(Checkpoint):
    def __init__(self):
        Checkpoint.__init__(self)
        self.id = 'F'

