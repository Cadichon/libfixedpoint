## Partie 1

Pour lancer se projet, il vous faut deux programmes :
- dub (version >= 1.19)
- dmd (version >= 2.090.1)

Pour les obtenir sur Ubuntu/Debian

``` bash
sudo wget https://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
sudo apt-get update --allow-insecure-repositories
sudo apt-get --allow-unauthenticated install d-apt-keyring
sudo apt-get update && sudo apt-get install dmd-compiler dub
```

Pour plus d'options: https://dlang.org/download.html

Une fois installé,

``` bash
dub test
```

Cela compilera la libfixedpoint et lancera les tests unitaires sur les opérations basiques (+, -, * et /).
Les tests unitaires utiliserons la méthode "toString" pour afficher les résultats des différentes opération.

## Partie 2
Les tests unitaires testerons aussi la méthode de Newton sur 15, en 0,1,2,3,4 et 5 passes.

## Partie 3
Une partie décimale plus petite, dans une représentation d'un nombre en point fixe, permet moins de liberté quand à la précision représentable.
On peut voir cela lorsque l'on essaye de convertir "68.2" en représentation en point fixe, avec une partie décimale sur 4 bits.
On ne peut pas obtenir "0.2" en additionnant des puissances de 2 négatives si l'on ne peut aller que jusqu'à 2^(-4).
C'est pour cela que, dans les tests unitaires, "62.8" devient "62.1875".

Lorsque l'on applique cela à la méthode de Newton, chaque itération de cette dernière nécessite de plus en plus de précision après la virgule,
qui ne peut pas etre représentée avec une partie décimale sur 4 bits.

Les deux derniers tests unitaires testent la méthode de Newton sur 15, en 0,1,2,3,4 et 5 passes, avec respectivement 8 et 16 bits de précision.
On voit bien que les résultats de cette dernière, sur des nombres pouvant stocker une partie décimale plus diversifiée, sont plus proches du vrai resultat.
