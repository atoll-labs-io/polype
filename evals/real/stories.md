
### s01-greeting — Une salutation en une ligne

**En tant que** visiteur du projet jetable **je veux** lire une salutation **afin de** savoir que le projet répond.

- **Complexité** : 2
- **Dépend de** : aucune
- **Surface** : command
- **Owns** : `src/s01-greeting.txt`, `checks/s01-greeting.check`

#### Critères d'acceptation
- [ ] `src/s01-greeting.txt` tient exactement la ligne `bonjour`.
- [ ] `checks/s01-greeting.check` échoue quand cette ligne manque ou change, et passe sinon.

### s02-farewell — Un au revoir qui suit la salutation

**En tant que** visiteur du projet jetable **je veux** lire un au revoir **afin de** savoir que le projet a fini de répondre.

- **Complexité** : 3
- **Dépend de** : aucune
- **Surface** : command
- **Owns** : `src/s02-farewell.txt`, `checks/s02-farewell.check`

#### Critères d'acceptation
- [ ] `src/s02-farewell.txt` tient exactement deux lignes : `au revoir`, puis `à bientôt`.
- [ ] `checks/s02-farewell.check` échoue quand l'une des deux lignes manque, change ou change de place, et passe sinon.
