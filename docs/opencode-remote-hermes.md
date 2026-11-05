# OpenCode local → Hermes distant (expérimental, chat uniquement)

Cette recette lance **OpenCode 1.19.5 sur le PC**, depuis un dépôt local, avec le
provider `@ai-sdk/openai-compatible` dirigé vers `/v1/chat/completions` de Hermes.
Elle ne démarre aucun service distant et ne modifie aucun déploiement serveur.
L'intégration Home Manager est **opt-in** et désactivée par défaut ; aucun hôte
n'est activé dans cette PR.

## Limites à lire avant utilisation

- L'API Hermes est une **API d'agent**, pas une API d'inférence brute. Les outils
  reçus dans une requête OpenAI ne deviennent pas des outils locaux OpenCode.
  Les outils que Hermes choisit d'appeler tournent **sur son serveur**.
- Le répertoire de lancement reste local mais n'est **pas monté ni synchronisé**
  dans Hermes. Cette recette ne permet donc pas de faire éditer automatiquement
  ce dépôt local par Hermes. Pour ce besoin, il faudra une autre architecture
  (provider d'inférence brut pour OpenCode, ou pont explicite d'outils locaux).
- Les permissions OpenCode ne restreignent **pas** les outils serveur Hermes.
  Utiliser un profil distant de test, sans outils d'écriture/exécution ni secrets
  de production. Le prompt de l'agent n'est pas une frontière de sécurité.
- **Blocage SSE reproduit avec le vrai OpenCode 1.19.5** : les événements nommés
  `hermes.tool.progress` sont rejetés avec `Type validation failed` par son SDK.
  Une instance de test peut désactiver ceux-ci avec
  `platforms.api_server.tool_progress_events: false` (option existante Hermes).
  Cela n'enlève pas tous les événements possibles : `hermes.status` et
  `approval.request` peuvent également être incompatibles. Un flux sans
  extensions est un prérequis ; les approbations distantes ne sont pas gérées.
  **Ne pas modifier la production pour essayer cette recette.** Le wrapper ne
  filtre pas les événements et `--check` ne vérifie pas la compatibilité SSE.
- La validation livrée couvre un serveur HTTP synthétique sur loopback, pas
  l'instance distante réelle. Aucun test d'inférence ni appel d'outil n'a été
  envoyé à la production. La mise en service distante reste à valider séparément.

## Activation déclarative Nix / Home Manager (recommandée)

Le module `modules/apps/opencode-hermes.nix` est importé par
`modules/apps/desktopsApps.nix`, déjà importé par `home.nix`. Les options suivent
le namespace existant `qgroget.nixos.apps.dev`, déclaré dans
`modules/options/qgroget.nix`. Exemple **dans un module Home Manager** (pas dans
la configuration système seule : ses options qgroget sont indépendantes) :

```nix
{
  qgroget.nixos.apps.dev = {
    enable = true;
    opencodeHermes = {
      enable = true;
      baseUrl = "http://127.0.0.1:18642/v1"; # tunnel vers un profil de test
      modelId = "hermes-agent";
    };
  };
}
```

Depuis un module NixOS de cette flake, utiliser
`home-manager.users.strange.qgroget.nixos.apps.dev.opencodeHermes = { ... };`
avec les mêmes valeurs, en gardant le parent `dev.enable = true` dans Home Manager.
Sur une configuration Home Manager indépendante, importer `settings.nix` et
`modules/apps/opencode-hermes.nix` explicitement. Rien n'est activé implicitement.

Après activation **sur le PC de test autorisé**, la commande `opencode-hermes`
est disponible : Python, le CLI OpenCode **1.19.5** et le JSON existant sont
référencés par chemins immuables du store, sans dépendre du clone ni d'un npm global.
Le package épinglé `modules/apps/opencode-hermes-package.nix` utilise l'archive
npm officielle avec hash SRI, patchée pour Nix. Le défaut supporte **x86_64-linux**
(binaire baseline sans exigence AVX2). L'option `package` permet une substitution
explicite ; une autre plateforme/version nécessite ses propres tests.

```bash
# Le tunnel de test doit déjà être ouvert ; aucune clé dans Nix ou le store.
read -r -s -p 'Clé du profil Hermes de test : ' HERMES_API_KEY; echo
export HERMES_API_KEY
opencode-hermes --check
opencode-hermes --workspace "$PWD" -- run 'Bonjour'
unset HERMES_API_KEY
```

`HERMES_API_BASE_URL` et `HERMES_MODEL_ID` peuvent remplacer les valeurs Nix à
l'exécution ; `HERMES_API_KEY` reste obligatoire à l'exécution. Ne jamais mettre
un bearer dans `baseUrl`, une option Nix ou `home.sessionVariables`. Le lanceur
ignore `OPENCODE_BIN` ambiant et impose le package choisi dans Nix. Désactiver
`opencodeHermes.enable` retire le lanceur et ses variables ; `dev.enable = false`
le désactive également. Aucune configuration globale OpenCode n'est écrasée.

Tests reproductibles sans activation ni déploiement :

```bash
nix eval --impure --raw --file tests/opencode-remote-check.nix evaluation
wrapper=$(nix build --impure --no-link --print-out-paths --file tests/opencode-remote-check.nix wrapper)
client=$(nix build --impure --no-link --print-out-paths --file tests/opencode-remote-check.nix package)
OPENCODE_WRAPPER="$wrapper/bin/opencode-hermes" OPENCODE_BIN="$client/bin/opencode" \
  python3 -B -W error::ResourceWarning -m unittest discover -s tests -p 'test_opencode_*.py' -v
```

L'évaluation utilise les entrées **racines** nixpkgs/Home Manager de `flake.lock`,
vérifie défaut désactivé, activation, désactivation du parent, substitution du
package et absence de clé. Le job CI `nix` construit puis exécute le lanceur
installable contre les mêmes fixtures SSE loopback que le client manuel.

## Installation manuelle alternative sur le PC

Python 3.10+, Node/npm pour installer OpenCode, accès à une instance **de test**
Hermes dont le serveur API est déjà activé et accessible. La clé client
`HERMES_API_KEY` correspond au secret **`API_SERVER_KEY`** du profil Hermes visé,
jamais à la clé du fournisseur LLM ni au token dashboard/OIDC.

Depuis le clone local de ce dépôt (Bash, Linux/macOS) :

```bash
# Installation utilisateur épinglée ; ne rien installer côté serveur.
npm install --global opencode-ai@1.19.5
opencode --version  # attendu : 1.19.5
```

Si votre politique npm bloque les scripts d'installation, examiner puis autoriser
le `postinstall` du package avec les mécanismes de votre version de npm. Ne pas
contourner globalement cette politique. Le test CI utilise npm standard.

## Transport et secret

Privilégier HTTPS direct vers un endpoint API de confiance, ou un tunnel SSH
**déjà autorisé** vers un port de test accessible depuis l'hôte SSH :

```bash
# Terminal 1, uniquement si 8642 est bien le port de TEST sur cet hôte.
# Pas de port public, pas de désactivation TLS, pas de redémarrage serveur.
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:18642:127.0.0.1:8642 utilisateur@hote-test
```

Un port loopback d'un conteneur n'est pas nécessairement joignable depuis l'hôte
SSH : vérifier le routage existant, ne pas ajouter de publication de port en
production. Une URL dashboard/Authelia n'est pas automatiquement une route API.
Le contrôle préalable refuse les redirections et n'utilise pas les proxies ambiants.
Le client OpenCode utilise ensuite son propre transport : employer une route API
finale, stable, sans redirection, et pas une page de login.

```bash
# Terminal 2, depuis la racine du clone local.
export HERMES_API_BASE_URL='http://127.0.0.1:18642/v1'
# Ou : export HERMES_API_BASE_URL='https://api-test.example.org/v1'
# Une URL de profil /p/<profil>/v1 convient si elle est déjà supportée/exposée.
export HERMES_MODEL_ID='hermes-agent'  # ID exact annoncé par ce profil /v1/models
read -r -s -p 'Clé API du profil Hermes de test : ' HERMES_API_KEY
printf '\n'
export HERMES_API_KEY

# GET /v1/models uniquement : auth, format et présence de l'ID choisi.
python3 scripts/opencode-remote.py --check

# Interface locale, agent hermes-chat, aucun outil local.
python3 scripts/opencode-remote.py --workspace "$PWD"

# Ou un seul échange : passer un titre évite aussi une génération implicite.
python3 scripts/opencode-remote.py --workspace "$PWD" -- \
  run --title 'Connexion Hermes de test' 'Réponds bonjour sans utiliser aucun outil.'

unset HERMES_API_KEY
```

Le bearer n'est ni écrit dans un fichier par le wrapper, ni passé dans `argv`.
Ne pas l'insérer dans `opencode.json`, un `.env` versionné, une capture, une PR,
`set -x` ou `--print-logs`. Il reste présent dans l'environnement du processus :
les processus du même utilisateur peuvent y accéder selon l'OS. OpenCode conserve
normalement les conversations dans son espace utilisateur ; ne pas y soumettre
contenu sensible sans politique de rétention adaptée. Les fichiers joints et
instructions de projet, chemins locaux et messages peuvent être envoyés au serveur.

## Configuration, comportement et arrêt

`examples/opencode/hermes.json` est un exemple opt-in, pas le `opencode.json` racine.
Le wrapper le charge via `OPENCODE_CONFIG_CONTENT` (priorité élevée) et utilise
`--pure` pour ne pas charger de plugins externes. Il ne modifie pas les configs
existantes. OpenCode fusionne néanmoins ses configurations : lancer uniquement
depuis un dépôt de confiance, vérifier les règles/MCP/instructions hérités et ne
pas considérer cette recette comme un sandbox. Ne pas ajouter `--auto` ni changer
d'agent pour essayer de contourner les restrictions.

- Seul le provider `hermes` est activé ; modèle principal et petit modèle pointent
  sur le même alias, sans repli vers un autre fournisseur.
- L'alias OpenCode reste `hermes/hermes-agent` ; son champ `id` prend
  `HERMES_MODEL_ID`. Ce dernier est un ID annoncé par Hermes, pas un profil choisi
  automatiquement ni une garantie de sélection d'un modèle upstream. Pour un profil
  nommé, l'URL **et** sa clé doivent désigner ce profil.
- Outils locaux refusés, partage/snapshots/mises à jour automatiques désactivés.
- Agents auxiliaires title/summary/compaction désactivés, auto-compaction coupée :
  évite que chaque génération de titre démarre aussi un agent distant. Le test
  vérifie exactement une requête d'inférence pour l'échange synthétique.
- Contexte 32768 et sortie 4096 sont des limites conservatrices du client, pas
  des capacités découvertes. Les adapter au profil de test si nécessaire.
- Timeout client 300 s, sans retry configuré, afin d'éviter des appels d'agent
  involontairement répétés. Arrêter le client ne garantit pas l'annulation de
  tout effet déjà produit par un outil serveur.

Arrêter OpenCode, fermer le tunnel et effacer la variable suffit au retour arrière.
Aucun `switch`, `deploy-hermes`, `systemctl` ou changement de service n'est requis.

## Vérification reproductible (hors production)

```bash
# Tests stdlib uniquement ; les deux tests CLI sont explicitement ignorés.
python3 -B -m unittest discover -s tests -p 'test_opencode_*.py' -v

# Inclure le vrai CLI 1.19.5, sans vraie clé ni connexion à Hermes :
OPENCODE_BIN="$(command -v opencode)" \
  python3 -B -W error::ResourceWarning -m unittest discover \
    -s tests -p 'test_opencode_*.py' -v

git diff --check
```

Les tests vérifient les variables manquantes, URLs dangereuses, injection d'en-tête,
401/403, refus de redirection, découverte des modèles, permissions et absence de
bearer sérialisé dans la config. Le CLI réel est lancé dans un répertoire et des
XDG/HOME temporaires isolés. Le serveur fixture répond avec un texte explicitement
synthétique, vérifie bearer/modèle/stream/absence d'outils et reproduit séparément
l'échec attendu des événements de progression. Ce n'est **pas** une réponse Hermes
réelle. Aucun build NixOS n'est requis par ces ajouts non importés ; la CI habituelle
du dépôt demeure indépendante.

## Sources consultées

- [Hermes : API server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
- [Hermes : intégration programmatique](https://hermes-agent.nousresearch.com/docs/developer-guide/programmatic-integration)
- [OpenCode : providers](https://opencode.ai/docs/providers/)
- [OpenCode : configuration et variables](https://opencode.ai/docs/config/)
- [OpenCode : agents auxiliaires et permissions](https://opencode.ai/docs/agents/)

L'étude préalable locale `work/hermes-remote-feasibility/FEASIBILITY.md` et le code
Hermes installé (`gateway/platforms/api_server.py`, `api_server_openai_routes.py`)
ont également été examinés. Ces chemins ne sont pas des dépendances de la recette.
