# Architecture Flutter - Couches du framework pour USMBA Social

L'application USMBA Social repose sur une architecture en couches adaptee au framework Flutter.
La couche superieure correspond a l'application elle-meme, avec les ecrans, widgets, themes
et providers qui portent la logique de presentation. Cette couche est visible dans des fichiers
comme `main.dart`, `screens/`, `widgets/` et `providers/`.

La deuxieme couche est celle du framework Flutter. Elle fournit les widgets Material,
la navigation, le rendu graphique, les animations et la gestion des interactions utilisateur.
USMBA Social s'appuie notamment sur `MaterialApp`, `Scaffold`, `Navigator`,
`StatefulWidget`, `StatelessWidget` et `Provider`.

La troisieme couche regroupe les services de communication et d'integration.
Elle contient les appels HTTP vers l'API backend, la communication temps reel avec Socket.IO,
le stockage local avec `SharedPreferences`, ainsi que l'integration de plugins comme
`google_sign_in`, `image_picker` et `file_picker`.

Enfin, la couche basse correspond au moteur Flutter et a la plateforme d'execution.
Elle permet a l'application de fonctionner sur le Web, Android et iOS a partir d'une base
de code Flutter unique.

## Point important pour le rapport

Dans cette application, la gestion d'etat observee dans le code reel repose principalement sur
`Provider` et `ChangeNotifier`, et non sur Riverpod. Il est donc recommande d'utiliser
la terminologie `Provider` dans le rapport afin de rester parfaitement conforme a l'implementation.
