# Planification du projet - USMBA Social

Ce document fournit les donnees necessaires pour tracer :

- un diagramme de Gantt
- un graphe MPM

## Hypotheses de planification

- Les durees sont exprimees en `jours ouvrables`
- `J0` represente le jour de demarrage du projet
- Les dates `au plus tot` et `au plus tard` sont relatives a `J0`
- Le planning correspond a une version realiste et academique du projet USMBA Social, basee sur les modules reels du systeme : authentification, profil, posts, stories, messagerie, notifications, administration, groupes, evenements

## Tableau principal des activites

| ID | Phase | Activite | Duree (jours) | Predecesseurs | Successeurs | Debut au plus tot | Fin au plus tot | Debut au plus tard | Fin au plus tard | Marge totale | Critique | Livrable principal |
| --- | --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| A01 | Initialisation | Cadrage du projet et planification initiale | 3 | - | A02 | 0 | 3 | 0 | 3 | 0 | Oui | Perimetre initial du projet |
| A02 | Analyse | Analyse des besoins et cahier des charges | 5 | A01 | A03, A04 | 3 | 8 | 3 | 8 | 0 | Oui | Besoins fonctionnels et non fonctionnels |
| A03 | Etude | Etude technologique et choix de la stack | 3 | A02 | A05 | 8 | 11 | 10 | 13 | 2 | Non | Choix Flutter, Node.js, MongoDB, Socket.IO |
| A04 | Conception | Conception UML et architecture generale | 5 | A02 | A05, A06 | 8 | 13 | 8 | 13 | 0 | Oui | Architecture globale et modeles UML |
| A05 | Conception | Conception de la base de donnees et des API | 4 | A03, A04 | A07, A08, A09 | 13 | 17 | 13 | 17 | 0 | Oui | Modeles de donnees et routes API |
| A06 | UI/UX | Maquettage UI/UX et navigation Flutter | 4 | A04 | A10 | 13 | 17 | 19 | 23 | 6 | Non | Maquettes des ecrans principaux |
| A07 | Backend | Developpement backend authentification et utilisateurs | 6 | A05 | A08, A10 | 17 | 23 | 17 | 23 | 0 | Oui | Inscription, connexion, profil, follow |
| A08 | Backend | Developpement backend posts, feed et interactions | 7 | A05, A07 | A09, A11 | 23 | 30 | 23 | 30 | 0 | Oui | Posts, likes, commentaires, sauvegarde, report |
| A09 | Backend | Developpement backend messagerie, stories et notifications temps reel | 7 | A05, A08 | A12, A13 | 30 | 37 | 31 | 38 | 1 | Non | Messages, stories, notifications, Socket.IO |
| A10 | Frontend | Developpement frontend authentification, profil et navigation | 7 | A06, A07 | A11 | 23 | 30 | 23 | 30 | 0 | Oui | Ecrans auth, profil, navigation |
| A11 | Frontend | Developpement frontend feed, posts, recherche et facultes | 8 | A08, A10 | A12, A13 | 30 | 38 | 30 | 38 | 0 | Oui | Feed complet et affichage des contenus |
| A12 | Frontend | Developpement frontend messagerie, stories et notifications | 7 | A09, A11 | A14 | 38 | 45 | 38 | 45 | 0 | Oui | Ecrans chat, stories, notifications |
| A13 | Modules annexes | Developpement des modules groupes, evenements et administration | 6 | A09, A11 | A14 | 38 | 44 | 39 | 45 | 1 | Non | Groupes, evenements, dashboard admin |
| A14 | Integration | Integration complete et tests fonctionnels | 5 | A12, A13 | A15, A16 | 45 | 50 | 45 | 50 | 0 | Oui | Version integree de l'application |
| A15 | Qualite | Securisation, optimisation et gestion des erreurs | 4 | A14 | A17 | 50 | 54 | 50 | 54 | 0 | Oui | Stabilite, securite et performance |
| A16 | Qualite | Tests automatises backend et corrections | 4 | A14 | A17 | 50 | 54 | 50 | 54 | 0 | Oui | Validation technique backend |
| A17 | Validation | Recette finale et stabilisation | 4 | A15, A16 | A18 | 54 | 58 | 54 | 58 | 0 | Oui | Version finale stable |
| A18 | Livraison | Documentation technique, rapport et preparation de soutenance | 6 | A17 | - | 58 | 64 | 58 | 64 | 0 | Oui | Rapport PFE et support de presentation |

## Chemin critique

Le reseau critique comporte plusieurs branches critiques convergentes.

Branche critique 1 :

`A01 -> A02 -> A04 -> A05 -> A07 -> A08 -> A11 -> A12 -> A14 -> A15 -> A17 -> A18`

Branche critique 2 :

`A01 -> A02 -> A04 -> A05 -> A07 -> A10 -> A11 -> A12 -> A14 -> A15 -> A17 -> A18`

Branche critique parallele en phase qualite :

`A14 -> A16 -> A17`

Duree totale du projet :

- `64 jours ouvrables`

## Jalons conseilles pour GanttProject

| ID | Jalon | Duree | Predecesseurs | Utilite |
| --- | --- | ---: | --- | --- |
| M01 | Validation du cahier des charges | 0 | A02 | Fin d'analyse |
| M02 | Architecture et conception validees | 0 | A05, A06 | Fin de conception |
| M03 | Backend principal termine | 0 | A09 | Fin du coeur backend |
| M04 | Frontend principal termine | 0 | A12 | Fin du coeur frontend |
| M05 | Version integree disponible | 0 | A14 | Premiere version complete |
| M06 | Projet final pret pour soutenance | 0 | A18 | Livraison finale |

## Conseils de tracage

### Pour le diagramme de Gantt

- Cree chaque activite `A01` a `A18`
- Saisis la duree en jours
- Ajoute les dependances avec la colonne `Predecesseurs`
- Ajoute ensuite les jalons `M01` a `M06`
- Choisis une date de debut reelle dans GanttProject, puis le logiciel calculera le calendrier

### Pour le graphe MPM

Chaque noeud doit contenir :

- le code de l'activite
- son intitule
- sa duree
- ses dates au plus tot / au plus tard si tu veux un graphe complet

Les arcs du graphe suivent les dependances de la colonne `Predecesseurs`.

## Version simplifiee pour saisie rapide

| ID | Activite | Duree | Predecesseurs |
| --- | --- | ---: | --- |
| A01 | Cadrage du projet et planification initiale | 3 | - |
| A02 | Analyse des besoins et cahier des charges | 5 | A01 |
| A03 | Etude technologique et choix de la stack | 3 | A02 |
| A04 | Conception UML et architecture generale | 5 | A02 |
| A05 | Conception de la base de donnees et des API | 4 | A03, A04 |
| A06 | Maquettage UI/UX et navigation Flutter | 4 | A04 |
| A07 | Developpement backend authentification et utilisateurs | 6 | A05 |
| A08 | Developpement backend posts, feed et interactions | 7 | A05, A07 |
| A09 | Developpement backend messagerie, stories et notifications temps reel | 7 | A05, A08 |
| A10 | Developpement frontend authentification, profil et navigation | 7 | A06, A07 |
| A11 | Developpement frontend feed, posts, recherche et facultes | 8 | A08, A10 |
| A12 | Developpement frontend messagerie, stories et notifications | 7 | A09, A11 |
| A13 | Developpement des modules groupes, evenements et administration | 6 | A09, A11 |
| A14 | Integration complete et tests fonctionnels | 5 | A12, A13 |
| A15 | Securisation, optimisation et gestion des erreurs | 4 | A14 |
| A16 | Tests automatises backend et corrections | 4 | A14 |
| A17 | Recette finale et stabilisation | 4 | A15, A16 |
| A18 | Documentation technique, rapport et preparation de soutenance | 6 | A17 |
