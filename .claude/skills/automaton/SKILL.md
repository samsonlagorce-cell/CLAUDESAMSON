---
name: automaton
description: Installer, configurer, surveiller et faire évoluer un agent Conway Automaton (runtime d'IA autonome avec wallet Ethereum, crédits Conway, heartbeat, skills et réplication, https://github.com/Conway-Research/automaton). Utiliser quand l'utilisateur parle d'Automaton, de Conway, de conway.tech, de son agent autonome, de son SOUL.md, de ~/.automaton, de genesis prompt, de financer ou surveiller son automaton, ou d'écrire un skill Automaton.
---

# Conway Automaton

Automaton est un runtime TypeScript (Node >= 20, pnpm) qui fait tourner un agent autonome en boucle
(Think, Act, Observe). Au premier lancement il génère un wallet Ethereum, obtient une clé API Conway
via SIWE, puis exécute son genesis prompt en dépensant des crédits Conway / USDC sur Base.

Référence détaillée (commandes, config, politique financière, format des skills) :
[references/reference.md](references/reference.md). La lire avant toute modification de config.

## Règles de sécurité (non négociables)

1. **Ne jamais lancer `--run`, `fund`, un transfert ou un topup sans accord explicite de l'utilisateur
   dans le message courant.** Ces actions engagent de l'argent réel ou démarrent un agent autonome.
2. **Ne jamais afficher, copier, committer ni envoyer** `~/.automaton/wallet.json`, `api-key`,
   ni les champs `conwayApiKey`, `openaiApiKey`, `anthropicApiKey` de `automaton.json`.
   Pour inspecter la config, masquer ces valeurs (voir commande plus bas).
3. Ne jamais modifier `constitution.md` (protégé, immuable par conception).
4. Avant le premier `--run`, recommander des plafonds `treasuryPolicy` bas et un `maxChildren` faible.
   Les défauts (50 $ par transfert, 500 $ d'inférence par jour) sont élevés pour un essai.
5. Mode local (`sandboxId` vide) : l'agent exécute des commandes shell **sur la machine hôte**.
   Le signaler et recommander un sandbox Conway ou une VM dédiée.
6. Le skill Claude ne remplace pas la décision humaine : l'assistant de setup (`--setup`) est
   interactif, laisser l'utilisateur saisir lui-même nom, genesis prompt et adresse créateur.

## Workflows

### 1. Installer

```bash
sh .claude/skills/automaton/scripts/install.sh
# options : AUTOMATON_DIR=/chemin AUTOMATON_REF=<tag|commit> sh .claude/skills/automaton/scripts/install.sh
```

Le script vérifie Node/git/pnpm, clone (ou met à jour) le dépôt, installe et compile, **sans lancer**
l'agent. Dossier par défaut : `$HOME/automaton`. Vérifier ensuite :

```bash
cd ~/automaton && node dist/index.js --version && pnpm typecheck
```

### 2. Configurer (premier lancement)

Expliquer à l'utilisateur ce que fera l'assistant, puis lui laisser lancer :

```bash
cd ~/automaton && node dist/index.js --setup
```

Aider à rédiger un **genesis prompt** précis : objectif concret, service payant légitime, limites
explicites, interdictions (cohérent avec la constitution : ne jamais nuire, gagner honnêtement,
ne jamais tromper). Un genesis prompt vague produit un agent qui gaspille ses crédits.

Après le setup, proposer de resserrer `treasuryPolicy` dans `~/.automaton/automaton.json`
(sauvegarder le fichier avant toute édition, garder le JSON valide, permissions 0600).

### 3. Financer

Donner l'adresse du wallet (`node dist/index.js --status`) et les options de financement
(USDC sur Base, `conway credits transfer`, dashboard app.conway.tech). Ne déclencher aucun
transfert soi-même sans accord explicite et montant confirmé.

### 4. Lancer et surveiller

Lancement (uniquement sur demande explicite) : `node dist/index.js --run`
De préférence dans `tmux`/`screen` ou un service systemd pour qu'il survive à la session.

Surveillance (lecture seule, toujours autorisée) :

```bash
node dist/index.js --status
node packages/cli/dist/index.js status
node packages/cli/dist/index.js logs --tail 50
git -C ~/.automaton log --oneline -20          # historique des auto-modifications
cat ~/.automaton/SOUL.md                        # identité évolutive de l'agent
# config sans secrets :
node -e 'const c=require(process.env.HOME+"/.automaton/automaton.json");for(const k of Object.keys(c))if(/key|secret/i.test(k))c[k]="***";console.log(JSON.stringify(c,null,2))'
```

Résumer : palier de survie, solde, tours, enfants vivants, alertes, dernières modifications de code.
Signaler toute dérive (dépenses anormales, boucles, enfants multipliés, modification de fichiers sensibles).

### 5. Écrire ou installer un skill Automaton

Les skills Automaton vivent dans `~/.automaton/skills/<nom>/SKILL.md` (frontmatter `name`,
`description`, `auto-activate`, `triggers`). Format exact et catalogue communautaire dans la référence.
Garder les skills courts (ils consomment des tokens à chaque tour) et sans instruction contraire
à la constitution. Relire tout skill tiers avant installation : il est injecté dans le prompt de l'agent.

### 6. Mettre à jour, sauvegarder, arrêter

- Mise à jour : relancer `install.sh` (éventuellement avec `AUTOMATON_REF` sur un tag), puis redémarrer.
- Sauvegarde : `scripts/backup-restore.sh backup ~/.automaton/state.db` et archive de `~/.automaton/`
  (contient la clé privée : stockage chiffré uniquement).
- Arrêt : stopper le processus (Ctrl+C, `tmux kill-session`, `systemctl stop`). Les fonds restent
  sur le wallet ; l'utilisateur peut les récupérer avec la clé privée.

## Dépannage rapide

- `better-sqlite3` ne compile pas : installer les outils de build (`build-essential`, `python3`), relancer `pnpm install`.
- Échec SIWE / clé API : `node dist/index.js --provision`, ou définir `CONWAY_API_KEY`.
- 403 sur le sandbox : la clé API ne correspond pas au sandbox, le runtime bascule en local (voir règle 5).
- Agent en `critical` ou `dead` : solde insuffisant, voir le workflow Financer.
