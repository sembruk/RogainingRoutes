"""
   Copyright 2025 Semyon Yakimov
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

from bs4 import BeautifulSoup
from classes import Member, Team, Checkpoint, Startpoint, Finishpoint, str_to_time

def parse_OEScore_splits_html(splits_filename):
    with open(splits_filename, "r", encoding="utf-8") as f:
        soup = BeautifulSoup(f, "lxml")

    print('Parse splits from OEScore:', splits_filename)

    # Get title
    event_title = soup.find("title").text.split(" - ")[0]

    #group_headers = soup.find_all("td", id="c00")
    tables = soup.find_all("table")

    teams = {}
    i = 0
    current_group = None

    while i < len(tables):
        table = tables[i]

        if table.find(id="c00"):
            current_group = table.get_text(strip=True).split(" (")[0].strip()
            print('Parse splits for:', current_group)
            teams[current_group] = []
            i += 2
            continue
        if current_group is None:
            i += 1
            continue

        team_table = tables[i]
        team_row = team_table.find("tr")

        tds = team_row.find_all("td")
        if len(tds) < 8:
            i += 1
            continue

        member = Member()
        member.place = tds[0].text.strip()
        member.team_bib = tds[1].text.strip()
        member.first_name = ''
        member.last_name = tds[2].text.strip()
        member.team_name = tds[3].text.strip()
        #print(member.team_name)
        #print(member.get_full_name())
        member.sum = tds[4].text.strip()
        member.sum = int(member.sum) if member.sum else 0
        time = tds[5].text.strip()
        member.time = str_to_time(time)
        member.penalty = tds[6].text.strip()
        member.penalty = int(member.penalty) if member.penalty else 0
        member.points = tds[7].text.strip()
        try:
            member.points = int(member.points)
        except (ValueError, TypeError):
            member.points = 0

        team = Team()
        team.group = current_group
        team.members.append(member)
        team.place = member.place
        team.team_name = member.team_name
        team.bib = member.team_bib
        team.time = member.time
        team.sum = member.sum
        team.points = member.points
        team.penalty = member.penalty

        # Таблица сплитов
        if i + 1 < len(tables):
            split_table = tables[i + 1]
            split_trs = split_table.find_all("tr")

            # Собираем строки с td id=rb
            cp_rows = [
                [td.text.strip() for td in tr.find_all("td") if td.get("id") == "rb"]
                for tr in split_trs
                if any(td.get("id") == "rb" for td in tr.find_all("td"))
            ]

            # Обработка: каждые 3 строки — набор для одного КП
            member.route.append(Startpoint())
            for j in range(0, len(cp_rows) - 2, 3):
                cp_id = cp_rows[j]
                abs_times = cp_rows[j + 1]
                rel_times = cp_rows[j + 2]

                for idx in range(min(len(cp_id), len(abs_times), len(rel_times))):
                    cp_str = cp_id[idx].strip()

                    is_finish = (cp_str.lower() == "meta")  # Spanish

                    if not cp_str:
                        continue

                    cp = None
                    if is_finish:
                        cp = Finishpoint()
                    elif '(' in cp_str:
                        cp = Checkpoint()
                        number, pts = cp_str.split("(")
                        cp.id = int(number.strip())
                        cp.points = int(pts.strip(")"))
                    cp.split = str_to_time(rel_times[idx])
                    cp.time = str_to_time(abs_times[idx])
                    member.route.append(cp)

            team.route = member.route
        teams[current_group].append(team)
            
        i += 2

    return teams, event_title

