# Derives the light "Papier clair" option from Main.dc.html (edit Main, then re-run).
s = open('Main.dc.html', encoding='utf-8').read()
rep = [
 ('#0A1428', '#F6F1E7'),
 ('color: #F6F1E7; font-family: Archivo', 'color: #1B2238; font-family: Archivo'),
 ('color: #F6F1E7', 'color: #1B2238'),
 ('#B9B3A5', '#5C5A52'),
 ('#9A8650', '#8A7430'),
 ('rgba(201,168,76,0.20)', 'rgba(201,168,76,0.30)'),
 ('opacity: 0.07', 'opacity: 0.05'),
 ('values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.9 0"', 'values="0 0 0 0 0.1  0 0 0 0 0.13  0 0 0 0 0.22  0 0 0 0.9 0"'),
 ('background: #C9A84C; color: #0B1529;', 'background: #1B2238; color: #F6F1E7;'),
 ('color: #0B1529;">Contactez-nous', 'color: #C9A84C;">Contactez-nous'),
 ('color: #0B1529;">Parlons de votre projet.', 'color: #E8C96A;">Parlons de votre projet.'),
 ('stroke: #0B1529;', 'stroke: #C9A84C;'),
 ('color: #3B3320', 'color: #C9A84C'),
 ('rgba(10,20,40,0.25)', 'rgba(201,168,76,0.35)'),
 ('color: #E8C96A; margin-top: 2px', 'color: #9A7810; margin-top: 2px'),
 ('text-transform: uppercase; color: #C9A84C;">Votre partenaire', 'text-transform: uppercase; color: #9A7810;">Votre partenaire'),
 ('text-transform: uppercase; color: #C9A84C;">Les six', 'text-transform: uppercase; color: #9A7810;">Les six'),
 ('stroke: #C9A84C; stroke-width: 2.4', 'stroke: #9A7810; stroke-width: 2.4'),
]
for a, b in rep: s = s.replace(a, b)
open('PapierClair.dc.html', 'w', encoding='utf-8').write(s)
# light-variant surfaces for the cards and chips
s = open('PapierClair.dc.html', encoding='utf-8').read()
for a, b in [
 ('linear-gradient(160deg, rgba(255,255,255,0.055), rgba(255,255,255,0.02))', 'linear-gradient(160deg, rgba(255,255,255,0.85), rgba(255,255,255,0.45))'),
 ('inset 0 1px 0 rgba(255,255,255,0.07)', '0 1px 0 rgba(27,34,56,0.06), 0 6px 18px rgba(27,34,56,0.06)'),
 ('rgba(232,201,106,0.22), rgba(201,168,76,0.06) 70%', 'rgba(232,201,106,0.35), rgba(201,168,76,0.10) 70%'),
 ('background: rgba(201,168,76,0.10); box-shadow: inset 0 0 0 1px rgba(201,168,76,0.30);', 'background: rgba(201,168,76,0.14); box-shadow: inset 0 0 0 1px rgba(154,120,16,0.35);'),
 ('.vig svg { width: 48px; height: 48px; fill: none; stroke: #C9A84C;', '.vig svg { width: 48px; height: 48px; fill: none; stroke: #9A7810;'),
]:
    s = s.replace(a, b)
open('PapierClair.dc.html', 'w', encoding='utf-8').write(s)
