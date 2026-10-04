#!/bin/sh
# Installe et compile le runtime Conway Automaton SANS le lancer.
# Le lancement (node dist/index.js --run) crée un wallet et peut dépenser
# des fonds : il doit rester une décision explicite de l'utilisateur.
#
# Variables :
#   AUTOMATON_DIR  dossier d'installation (défaut : $HOME/automaton)
#   AUTOMATON_REF  branche, tag ou commit à utiliser (défaut : main)
set -eu

REPO="https://github.com/Conway-Research/automaton.git"
INSTALL_DIR="${AUTOMATON_DIR:-$HOME/automaton}"
REF="${AUTOMATON_REF:-main}"

command -v node >/dev/null 2>&1 || { echo "[ERREUR] Node.js >= 20 requis." >&2; exit 1; }
NODE_MAJOR=$(node -e "process.stdout.write(process.versions.node.split('.')[0])")
[ "$NODE_MAJOR" -ge 20 ] || { echo "[ERREUR] Node.js >= 20 requis, trouvé $(node -v)." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "[ERREUR] git requis." >&2; exit 1; }

if ! command -v pnpm >/dev/null 2>&1; then
  echo "[INFO] Activation de pnpm via corepack..."
  corepack enable pnpm || { echo "[ERREUR] Installe pnpm : npm i -g pnpm" >&2; exit 1; }
fi

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[INFO] Mise à jour de $INSTALL_DIR ($REF)..."
  git -C "$INSTALL_DIR" fetch --depth 1 origin "$REF"
  git -C "$INSTALL_DIR" checkout --detach FETCH_HEAD
else
  echo "[INFO] Clonage dans $INSTALL_DIR ($REF)..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 --branch "$REF" "$REPO" "$INSTALL_DIR" 2>/dev/null || {
    git clone "$REPO" "$INSTALL_DIR"
    git -C "$INSTALL_DIR" checkout --detach "$REF"
  }
fi

cd "$INSTALL_DIR"
echo "[INFO] Installation des dépendances..."
pnpm install --frozen-lockfile
echo "[INFO] Compilation..."
pnpm run build

echo
echo "[OK] Automaton installé dans $INSTALL_DIR ($(git rev-parse --short HEAD))"
echo "     Version : $(node -p "require('./package.json').version")"
echo "     Étape suivante (manuelle, crée un wallet) : cd $INSTALL_DIR && node dist/index.js --setup"
