#!/usr/bin/env python3
"""Dessine les tables et clés étrangères SQL selon les trois vues du MPD draw.io."""
from html import escape, unescape
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sql = (ROOT / "Base de donnees.sql").read_text(encoding="utf-8-sig")
tables = dict(re.findall(r"CREATE TABLE\s+(\w+)\s*\((.*?)\)\s*ENGINE", sql, re.S))
views = ET.parse(ROOT / "palimpseste_mpd.drawio").getroot().findall("diagram")
titles = ["Fragments et collections", "Groupes et demandes d’avis", "Réapparition, historique et bilans"]
covered = set()
out = ROOT / "docs"
out.mkdir(exist_ok=True)
for index, view in enumerate(views):
    names = []
    for cell in view.findall(".//mxCell"):
        if "shape=table;" in cell.get("style", ""):
            name = unescape(re.sub(r"<[^>]+>", "", cell.get("value", "")))
            if name not in tables:
                raise ValueError(f"Table du MPD absente du SQL : {name}")
            if name not in names:
                names.append(name)
    covered.update(names)
    lines = ['digraph Schema {',
             'graph [rankdir=TB, bgcolor="#fffdf8", pad="0.3", nodesep="0.4", ranksep="0.7", fontname="DejaVu Sans", fontsize=18, labelloc=t, label=' + '"' + titles[index] + '"];',
             'node [shape=plain, fontname="DejaVu Sans", fontsize=11];',
             'edge [color="#6b7d70", arrowsize=0.65, fontname="DejaVu Sans", fontsize=9];']
    for name in names:
        body = tables[name]
        pk = set()
        for fields in re.findall(r"PRIMARY KEY\s*\(([^)]+)\)", body):
            pk.update(field.strip() for field in fields.split(","))
        fk = set(re.findall(r"FOREIGN KEY\s*\((\w+)\)", body))
        rows = []
        for column, kind in re.findall(r"^\s*(\w+)\s+([A-Z]+)(?:\([^\n]*?\))?[^\n]*", body, re.M):
            if column in {"CONSTRAINT", "PRIMARY", "FOREIGN", "UNIQUE", "CHECK"}:
                continue
            key = "PK " if column in pk else ""
            key += "FK " if column in fk else ""
            rows.append(f'<TR><TD ALIGN="LEFT">{key}</TD><TD ALIGN="LEFT">{escape(column)}</TD><TD ALIGN="LEFT">{kind}</TD></TR>')
        label = '<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="5" COLOR="#b6c2b5"><TR><TD COLSPAN="3" BGCOLOR="#173f35"><FONT COLOR="white"><B>' + name + '</B></FONT></TD></TR>' + ''.join(rows) + '</TABLE>'
        lines.append(f'"{name}" [label=<{label}>];')
    for name in names:
        for source, target, dest in re.findall(r"FOREIGN KEY\s*\((\w+)\)\s*REFERENCES\s+(\w+)\s*\((\w+)\)", tables[name]):
            if target in names:
                lines.append(f'"{name}" -> "{target}" [label="{source} → {dest}"];')
    lines.append('}')
    dot = out / f"schema-{index+1}.dot"
    dot.write_text('\n'.join(lines)+'\n', encoding="utf-8")
    subprocess.run(["dot", "-Tsvg", str(dot), "-o", str(out / f"schema-{index+1}.svg")], check=True)
if covered != set(tables):
    raise ValueError(f"Couverture des tables incomplète : {set(tables) - covered}")
print(f"3 vues générées ; {len(covered)} tables couvertes. Flèche : clé étrangère vers table référencée.")
