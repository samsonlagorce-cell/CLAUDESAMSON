# Référence Conway Automaton

Source : https://github.com/Conway-Research/automaton (README.md, DOCUMENTATION.md, ARCHITECTURE.md).
En cas de doute, relire `DOCUMENTATION.md` dans le dossier d'installation : il fait foi.

## Runtime (`node dist/index.js`)

| Commande | Effet | Risque |
|---|---|---|
| `--help`, `--version` | Aide, version | aucun |
| `--status` | Nom, adresse, état, tours, skills, enfants, modèle | lecture seule |
| `--init` | Crée `~/.automaton/` et le wallet uniquement | crée une clé privée |
| `--provision` | Obtient une clé API Conway via SIWE | appel réseau signé |
| `--setup` | Assistant interactif complet (wallet, clé API, nom, genesis prompt, adresse créateur, politique financière) | interactif |
| `--run` | Lance la boucle autonome (setup au premier lancement) | dépense des crédits, agit en autonomie |

Variables d'environnement : `CONWAY_API_URL` (défaut `https://api.conway.tech`), `CONWAY_API_KEY` (prioritaire sur le fichier de config).

## CLI créateur (`node packages/cli/dist/index.js`)

| Commande | Effet |
|---|---|
| `status` | État de l'automaton |
| `logs [--tail N]` | Journaux |
| `fund <montant> [--to 0x...]` | Transfère des crédits Conway (argent réel) |
| `send <adresse> <message>` | Envoie un message social à un agent |

## Fichiers (`~/.automaton/`)

```
wallet.json      clé privée Ethereum (0600) : NE JAMAIS afficher ni committer
automaton.json   configuration principale (0600, contient des clés API)
api-key          clé API Conway
heartbeat.yml    planning du heartbeat
constitution.md  les trois lois (0444, immuable)
SOUL.md          identité auto-rédigée de l'agent
state.db         base SQLite (tout l'état)
skills/<nom>/SKILL.md  skills installés
```

`~/.automaton/` est un dépôt git : `git -C ~/.automaton log --oneline` montre l'historique des modifications.

## Configuration (`automaton.json`), champs principaux

- Identité : `name`, `genesisPrompt`, `creatorMessage`, `creatorAddress`, `walletAddress`
- Infra : `sandboxId` (vide = mode local, les commandes shell s'exécutent sur la machine hôte), `conwayApiUrl`, `conwayApiKey`
- Inférence : `inferenceModel`, `maxTokensPerTurn`, `openaiApiKey`, `anthropicApiKey`
- Comportement : `logLevel` (debug|info|warn|error), `maxChildren` (défaut 3), `socialRelayUrl`
- `treasuryPolicy` : voir ci-dessous

## Politique financière (`treasuryPolicy`), valeurs par défaut en cents

| Clé | Défaut |
|---|---|
| `maxSingleTransferCents` | 5000 (50 $) |
| `maxHourlyTransferCents` | 10000 (100 $) |
| `maxDailyTransferCents` | 25000 (250 $) |
| `minimumReserveCents` | 1000 (10 $) |
| `maxX402PaymentCents` | 100 (1 $) |
| `x402AllowedDomains` | `["conway.tech"]` |
| `maxTransfersPerTurn` | 2 |
| `maxInferenceDailyCents` | 50000 (500 $) |
| `requireConfirmationAboveCents` | 1000 (10 $) |

Ces défauts sont élevés pour un premier essai : proposer des plafonds bas (par exemple 500 / 1000 / 2000 / reserve 200 / inférence 1000).

## Financement

- USDC sur Base vers l'adresse du wallet de l'agent
- `conway credits transfer <adresse> <montant>` depuis un autre compte Conway
- Dashboard https://app.conway.tech
- Auto-topup au démarrage : si crédits < 5 $ et USDC >= 5 $, achat automatique de 5 $ de crédits.
- Paliers `topup_credits` : 5, 25, 100, 500, 1000, 2500 $.

## Paliers de survie

`normal` > `low_compute` (modèle moins cher, heartbeat ralenti) > `critical` > `dead` (solde nul, arrêt).

## Skills Automaton (à ne pas confondre avec les skills Claude Code)

Format : `~/.automaton/skills/<nom>/SKILL.md`

```markdown
---
name: mon-skill
description: "Ce que fait le skill"
auto-activate: true
triggers: [mot1, mot2]
---
# Instructions
...
```

Skills par défaut : `conway-compute`, `conway-payments`, `survival`.
Catalogue communautaire : https://github.com/Conway-Research/skills (par exemple `conway-cloud`).

## Sauvegarde

```bash
scripts/backup-restore.sh backup ~/.automaton/state.db [chemin_backup]
scripts/backup-restore.sh restore <backup> ~/.automaton/state.db
scripts/backup-restore.sh verify ~/.automaton/state.db
tar czf automaton-backup-$(date +%Y%m%d).tar.gz ~/.automaton/   # contient la clé privée : stocker en lieu sûr
```

## Développement

```bash
pnpm typecheck
pnpm test            # vitest
pnpm test:security   # tests sécurité / injection / policy
pnpm test:financial  # tests dépenses / trésorerie
```
