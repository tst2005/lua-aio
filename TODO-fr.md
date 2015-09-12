* supporter l'utilisation de debug.getinfo(2).source ?

* des fonctions pour codebefore(patt) et codeafter(patt)
* voir a utiliser une autre variable global que _ pour le shellcode ... _SHELLCODE ? _SH ?
* du code pour qu'au runtime le preload detecte sil y a deja des preload present plutot que de les ecraser betement
  * creer du code pour un preload-manager ?
  * utiliser un pcall+require"preloadmanager" ?
preload.add(name, func , {pri=1} )
* pouvoir dans le make-all-in-one preciser si on veux etre agressif ou non

* au runtime, des tests avancés pour déterminer la version ??
