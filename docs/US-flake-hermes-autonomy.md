# US — Autonomie du déploiement hermes sans élargir ses privilèges

_Statut : Proposition · Repo : nixos-config · Auteur : @strange500 + hermes-agent_

---

## Problème (pourquoi)

L'agent hermes doit pouvoir déployer **en autonomie** ses services de test
(instances rootless, services `systemd.user`, conteneurs >1024, etc.) sans jamais
être capable de modifier quoi que ce soit en dehors de son propre utilisateur.

Aujourd'hui sa config vit dans `./home/hermes.nix`, consommée comme un **input
interne** de nixos-config. Le problème : hermes partage l'évaluation racine de
`nixos-rebuild`/comin. Un merge hermes cassé peut donc :

- faire échouer le build du toplevel système (bloquant pour tout le monde), et
- si l'input n'est pas strictement scopé, laisser du code hermes s'injecter
  dans des modules système.

En parallèle, `.github/workflows/update.yml` (existant) fait un
`nix flake update` **global** + **git push direct sur main** : cela rebat tous
les inputs en même temps, contourne la règle PR, et peut promouvoir des
régressions sans validation.

## Objectif

Deux flakes + une interface de consommation unique **user-scopée** :

- `strange500/hermes-services` : **ne fournit que** `homeConfigurations.hermes`
  (un home-manager user rootless). Aucun `nixosConfigurations`, aucun module
  système, aucun daemon root.
- nixos-config : consomme cet input **uniquement** sous
  `homeConfigurations.hermes`, versionné par `flake.lock`.
- Un updater scopé remplace le `nix flake update` global par
  `nix flake lock --update-input hermes-services` + **PR** (validation CI puis
  merge), pas de push direct.

La séparation en deux flakes n'isole pas les privilèges par elle-même — ce qui
isole, c'est l'**engin** qui applique le code (`home-manager switch` rootless
vs `nixos-rebuild` root) **et** le point d'ancrage dans nixos-config. Cette US
verrouille les trois.

## User Story

> **En tant que** Strange (admin du serveur),  
> **je veux** que hermes publie ses services de test dans un flake indépendant
> `hermes-services` qui ne déclare qu'un user home-manager rootless, intégré à
> nixos-config comme input versionné par le lock,  
> **afin que** je puisse donner à hermes une autonomie de déploiement complète
> sur ses services de test sans qu'il puisse, même par erreur ou volontairement,
> toucher au système ou à d'autres utilisateurs.

## Critères d'acceptation (DoD)

1. **Séparation** : le contenu de `./home/hermes.nix` est déplacé dans un
   dépôt `strange500/hermes-services` dont le flake expose
   `outputs.homeConfigurations.hermes` (foo bar : seul output home-manager ;
   aucun `nixosConfigurations.*`).
2. **Input déclaré** dans `flake.nix` de nixos-config :
   ```nix
   inputs.hermes-services = {
     url = "github:strange500/hermes-services";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
   et `homeConfigurations.hermes.modules = [ inputs.hermes-services.homeConfigurations.hermes ];`
   — le seul point où l'input est consommé.
3. **Verrou : l'input n'est consommé QUE sous `homeConfigurations.hermes`**.
   Il n'apparaît dans **aucun** chemin de toplevel système
   (`nixosConfigurations.Server` etc.). Un grep cross-référence
   (`hermes-services`) ne doit matcher que dans `flake.nix` (input) et le bloc
   `homeConfigurations.hermes`.
4. **Rester rootless** : le service continue de ne cibler que `/home/hermes`,
   ports >1024, `systemd.user`. Aucun `users.users.hermes.extraGroups`
   privilégié ajouté via cet input (la coquille système de l'user — uid, shell,
   groupes — reste possédée par nixos-config, PAS par hermes-services).
5. **Updater scopé** : le CI remplace `update.yml` (ou le restreint) par un
   workflow qui fait uniquement :
   ```bash
   nix flake lock --update-input hermes-services   # touche SEUL cet input
   ```
   puis ouvre une **PR** `chore(nixos-config): bump hermes-services → <rev>`
   (pas de push sur main). La CI existante (Build Server + flake check)
   valide le build de la PR ; l'auto-merge est activable si tous les checks
   passent.
6. **Chaîne complète** : merge sur `hermes-services` → updater scopé bump le
   lock (≤30 min) → PR nixos-config → CI verte → merge → comin poll le `main`
   et déploie `homeManager` de hermes. Rien d'autre n'est déclenché.
7. **Filet de sécurité build** : si `hermes-services` casse le build, la PR de
   bump lock est bloquée par la CI ; le serveur ne reçoit pas le changement.
   Aucun `nix flake update` global non contrôlé.

## Design / Implémentation

### 1. Dépôt `strange500/hermes-services`
- `flake.nix` :
  ```nix
  {
    inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };
    outputs = { self, nixpkgs, ... }: {
      homeConfigurations.hermes = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./hermes.nix ];
      };
    };
  }
  ```
- `hermes.nix` : copie de l'actuel `./home/hermes.nix` (services rootless,
  `deploy-hermes`, portfolio-test, traefik-router user).
- CI : `nix flake check` + build de `homeConfigurations.hermes` sur PR.

### 2. nixos-config
- Remplacer le `homeConfigurations.hermes.modules = [ ./home/hermes.nix ]`
  (ligne ~256 de `flake.nix`) par l'input `hermes-services`.
- Conserver dans `home.nix`/flake la **coquille système** de l'user hermes
  (`users.users.hermes` : uid, shell, groupes), jamais déléguée à l'input.
- Ancrer la vérif CI : une étape qui fail si `hermes-services` est référencé
  hors du bloc `homeConfigurations.hermes`.

### 3. Workflow updater scopé (remplace l'`update.yml` actuel)
```yaml
name: Update hermes-services input
on:
  schedule: [{ cron: "*/30 * * * *" }]
  workflow_dispatch:
jobs:
  bump:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v27
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - run: nix flake lock --update-input hermes-services
      - id: diff
        run: git diff --exit-code flake.lock || echo "changed=1" >> "$GITHUB_OUTPUT"
      - if: steps.diff.outputs.changed == '1'
        uses: peter-evans/create-pull-request@v6
        with:
          branch: deps/hermes-services
          title: "chore(nixos-config): bump hermes-services"
          body: "Update lock for input `hermes-services`."
```

## Points de vigilance / pièges

- **`update.yml` actuel = danger** : `nix flake update` global + push direct
  main. Le supprimer/le mettre hors service AVANT d'ajouter le workflow scopé,
  sinon deux bots se battent sur le lock.
- **home-manager version en module vs standalone** : l'actuel est en
  `home-manager` module NixOS (via `modules/system/home-manager.nix` +
  `homeConfigurations.hermes`). Un bug de build de l'user hermes fait échouer
  `nixos-rebuild` entier. La migration vers un home-manager **standalone**
  (déjà le pattern de `deploy-hermes` / PR #53) est plus étanche — à arbitrer.
- **Le lock RÉ-injecte hermes dans l'éval racine** : c'est voulu (critère 6,
  le filet build), mais c'est la raison pour laquelle le point d'ancrage doit
  rester strictement sous `homeConfigurations.hermes`.
- **Pas de token supplémentaire** : le workflow scopé tourne avec `GITHUB_TOKEN`
  par défaut ; le repo est public, pas d'auth nécessaire pour le lock.

## Hors périmètre
- Services nécessitant du privilège root (ports <1024, groupes système, infra
  kernel) → PAS scopables à hermes, restent dans nixos-config via comin.
- Migration système de l'user hermes hors de l'input (critère 4).