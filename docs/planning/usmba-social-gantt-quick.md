# Tableau rapide - GanttProject - USMBA Social

Hypothese retenue :

- debut du projet : `01/12/2025`
- fin du projet : `31/03/2026`
- durees en `jours ouvrables`

## Tableau a saisir rapidement dans GanttProject

Cette version met davantage en valeur le travail en parallele entre :

- conception technique et maquettage
- backend et frontend
- implementation et redaction du rapport

| ID | Activite | Debut | Fin | Duree (jours) | Predecesseurs | Parallele avec | Successeurs |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| A01 | Cadrage du projet et planification initiale | 01/12/2025 | 05/12/2025 | 5 | - | - | A02 |
| A02 | Analyse des besoins et cahier des charges | 08/12/2025 | 19/12/2025 | 10 | A01 | - | A03, A04 |
| A03 | Conception UML, architecture, base de donnees et API | 22/12/2025 | 09/01/2026 | 15 | A02 | A04 | A05 |
| A04 | Maquettage UI/UX et navigation Flutter | 22/12/2025 | 02/01/2026 | 10 | A02 | A03 | A07 |
| A05 | Developpement backend authentification et utilisateurs | 12/01/2026 | 23/01/2026 | 10 | A03 | A07 | A06 |
| A06 | Developpement backend posts, feed et interactions | 26/01/2026 | 06/02/2026 | 10 | A05 | A07 | A08 |
| A07 | Developpement frontend authentification, profil et navigation | 13/01/2026 | 26/01/2026 | 10 | A04 | A05, A06 | A09 |
| A08 | Developpement backend messagerie, stories et notifications | 09/02/2026 | 20/02/2026 | 10 | A06 | A09 | A10, A11 |
| A09 | Developpement frontend feed, posts, recherche et facultes | 03/02/2026 | 16/02/2026 | 10 | A07 | A08 | A10, A11, A14 |
| A10 | Developpement frontend messagerie, stories et notifications | 23/02/2026 | 06/03/2026 | 10 | A08, A09 | A11 | A12 |
| A11 | Developpement des modules groupes, evenements et administration | 23/02/2026 | 06/03/2026 | 10 | A08, A09 | A10 | A12, A14 |
| A12 | Integration complete et tests fonctionnels | 09/03/2026 | 18/03/2026 | 8 | A10, A11 | A14 | A13 |
| A13 | Tests, corrections, securisation et optimisation | 19/03/2026 | 25/03/2026 | 5 | A12 | A14 | M01 |
| A14 | Documentation finale, rapport et preparation de soutenance | 16/03/2026 | 31/03/2026 | 12 | A11 | A12, A13 | M01 |
| M01 | Fin du projet / projet pret pour soutenance | 31/03/2026 | 31/03/2026 | 0 | A13, A14 | - | - |

## Version ultra-courte si tu veux juste saisir les dependances

| ID | Activite | Duree | Predecesseurs |
| --- | --- | ---: | --- |
| A01 | Cadrage du projet et planification initiale | 5 | - |
| A02 | Analyse des besoins et cahier des charges | 10 | A01 |
| A03 | Conception UML, architecture, base de donnees et API | 15 | A02 |
| A04 | Maquettage UI/UX et navigation Flutter | 10 | A02 |
| A05 | Developpement backend authentification et utilisateurs | 10 | A03 |
| A06 | Developpement backend posts, feed et interactions | 10 | A05 |
| A07 | Developpement frontend authentification, profil et navigation | 10 | A04 |
| A08 | Developpement backend messagerie, stories et notifications | 10 | A06 |
| A09 | Developpement frontend feed, posts, recherche et facultes | 10 | A07 |
| A10 | Developpement frontend messagerie, stories et notifications | 10 | A08, A09 |
| A11 | Developpement des modules groupes, evenements et administration | 10 | A08, A09 |
| A12 | Integration complete et tests fonctionnels | 8 | A10, A11 |
| A13 | Tests, corrections, securisation et optimisation | 5 | A12 |
| A14 | Documentation finale, rapport et preparation de soutenance | 12 | A11 |
| M01 | Fin du projet / projet pret pour soutenance | 0 | A13, A14 |
