# UML - USMBA Social

Ce dossier contient un diagramme de cas d'utilisation global du projet USMBA Social.

## Fichier principal

- `usmba-social-use-case.puml` : code PlantUML du diagramme

## Acteurs retenus

- `Visiteur`
- `Utilisateur authentifie`
- `Administrateur`
- `Service Google` comme acteur externe pour l'authentification Google
- `Service Email` comme acteur externe pour la verification et la reinitialisation

## Pourquoi cette structure

Le projet contient beaucoup de modules : authentification, profils, posts, stories,
messagerie, notifications, facultes, groupes, evenements et administration.

Pour garder un diagramme lisible dans un rapport PFE, les cas d'utilisation ont ete
organises par grands blocs fonctionnels. Les sous-fonctions importantes sont reliees
avec `<<include>>` ou `<<extend>>`.

- `<<include>>` : sous-fonction obligatoire
- `<<extend>>` : sous-fonction optionnelle

Exemples :

- `Publier un post` `<<extend>>` `Ajouter un media`
- `Envoyer un message` `<<extend>>` `Joindre un fichier`
- `Interagir avec un post` `<<include>>` like, commentaire, sauvegarde, signalement

## Outils conseilles

### Option 1 - PlantUML

La meilleure option si tu veux generer rapidement une image a partir du fichier deja cree.

Tu peux utiliser :

- l'extension VS Code `PlantUML`
- le site `planttext.com`
- n'importe quel viewer PlantUML

Etapes :

1. Ouvrir `usmba-social-use-case.puml`
2. Generer l'aperçu
3. Exporter en `PNG` ou `SVG`
4. Inserer l'image dans Word

### Option 2 - diagrams.net

La meilleure option si tu veux refaire le diagramme a la main avec un style plus personnalise.

Etapes :

1. Ouvrir `draw.io` / `diagrams.net`
2. Choisir `UML Use Case`
3. Ajouter les acteurs a gauche et a droite
4. Creer une grande frontiere `Systeme USMBA Social`
5. Ajouter les cas d'utilisation par blocs :
   authentification, profil, publications, messagerie, administration
6. Relier :
   - acteurs -> cas d'utilisation
   - `Administrateur` herite de `Utilisateur authentifie`
   - `include` pour les sous-fonctions obligatoires
   - `extend` pour les options comme media et pieces jointes

## Recommandation pour le rapport

Si tu veux un diagramme unique a inserer dans le rapport, garde cette version globale.
Si ton encadrant prefere plus de detail, tu peux ensuite la decliner en 3 diagrammes :

- Authentification et profil
- Publications, stories, messagerie et notifications
- Administration, groupes, facultes et evenements

## Liste minimale des cas d'utilisation a garder si tu veux simplifier

- S'inscrire
- Se connecter
- Gerer le profil
- Consulter le feed
- Publier un post
- Interagir avec un post
- Gerer les stories
- Utiliser la messagerie
- Consulter les notifications
- Rechercher dans la plateforme
- Consulter les facultes
- Utiliser les groupes
- Utiliser les evenements
- Acceder au dashboard administrateur
- Gerer les utilisateurs
- Traiter les signalements
