#!/usr/bin/env bash
# Installe tout ce qu'il faut sur macOS, compile le plugin et lance un serveur
# Paper 1.16.5 de test avec le plugin dedans.
#
# Utilisation (depuis le dossier du projet) :
#   bash mac-setup.sh
#
# Relancer le script plus tard recompile le plugin et redemarre le serveur.

set -euo pipefail

MC_VERSION="1.16.5"
PAPER_FALLBACK_BUILD="794" # dernier build Paper publie pour 1.16.5
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$PROJECT_DIR/server"

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$1"; }

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Ce script est fait pour macOS." >&2
  exit 1
fi

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  say "Installation de Homebrew (il va te demander ton mot de passe Mac)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 2. Java 11 (compatible Minecraft 1.16.5) + Maven
say "Installation de Java 11 et Maven"
brew list openjdk@11 >/dev/null 2>&1 || brew install openjdk@11
brew list maven >/dev/null 2>&1 || brew install maven

JAVA_HOME="$(brew --prefix openjdk@11)/libexec/openjdk.jdk/Contents/Home"
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"
java -version

# 3. Compilation du plugin
say "Compilation du plugin"
cd "$PROJECT_DIR"
mvn -B -q package
PLUGIN_JAR="$(ls target/MobLookMultiply-*.jar | grep -v original | head -n 1)"
echo "Plugin compile : $PLUGIN_JAR"

# 4. Serveur Paper 1.16.5
mkdir -p "$SERVER_DIR/plugins"
cd "$SERVER_DIR"

if [[ ! -f paper.jar ]]; then
  say "Telechargement de Paper $MC_VERSION"
  PAPER_URL=""
  if META="$(curl -fsSL -H 'User-Agent: MobLookMultiply-setup' \
      "https://fill.papermc.io/v3/projects/paper/versions/$MC_VERSION/builds/latest" 2>/dev/null)"; then
    PAPER_URL="$(printf '%s' "$META" | plutil -extract downloads.server:default.url raw -o - - 2>/dev/null || true)"
  fi
  if [[ -z "$PAPER_URL" ]]; then
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_FALLBACK_BUILD/downloads/paper-$MC_VERSION-$PAPER_FALLBACK_BUILD.jar"
  fi
  echo "Source : $PAPER_URL"
  curl -fL -o paper.jar "$PAPER_URL"
fi

cp "$PROJECT_DIR/$PLUGIN_JAR" plugins/MobLookMultiply.jar

# 5. EULA Minecraft (doit etre acceptee par toi)
if ! grep -q 'eula=true' eula.txt 2>/dev/null; then
  echo
  echo "Pour lancer un serveur, tu dois accepter l'EULA de Minecraft :"
  echo "  https://aka.ms/MinecraftEULA"
  read -r -p "Tu acceptes l'EULA ? (o/n) " answer
  if [[ "$answer" =~ ^[oOyY] ]]; then
    echo "eula=true" > eula.txt
  else
    echo "EULA refusee, le serveur ne peut pas demarrer."
    exit 1
  fi
fi

# 6. Lancement
say "Lancement du serveur"
echo "Dans Minecraft Java $MC_VERSION : Multijoueur > Ajouter un serveur > adresse 'localhost'"
echo "Dans cette console, tape :  op <ton_pseudo>"
echo "En jeu, tape :              /moblook start"
echo "Pour arreter le serveur :   stop"
echo
exec java -Xms1G -Xmx2G -jar paper.jar nogui
