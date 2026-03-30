#!/usr/bin/env bash
# install.sh — Install ios-build-speed-skills into Claude Code
# Requirements: bash 3.2+
# Usage:
#   ./install.sh              # interactive
#   ./install.sh --global     # install to ~/.claude/skills/ios-build-speed/
#   ./install.sh --local      # install to ./.claude/skills/ios-build-speed/
#   ./install.sh --force      # overwrite without prompt (install only)
#   ./install.sh --uninstall --global
#   ./install.sh --uninstall --local

set -euo pipefail

SKILLS_DIR_NAME="ios-build-speed"
REPO_URL="https://github.com/cruisediary/ios-build-speed-skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/skills"
TEMP_DIR=""

SCOPE=""
FORCE=false
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --global)    SCOPE="global"   ;;
    --local)     SCOPE="local"    ;;
    --force)     FORCE=true       ;;
    --uninstall) UNINSTALL=true   ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: ./install.sh [--global|--local] [--force] [--uninstall]"
      exit 1
      ;;
  esac
done

# --force is not valid with --uninstall
if $UNINSTALL && $FORCE; then
  echo "Error: --force cannot be used with --uninstall."
  exit 1
fi

# Prompt for scope if not provided
if [ -z "$SCOPE" ]; then
  echo "Where do you want to install ios-build-speed skills?"
  echo "  1) Global — ~/.claude/skills/ (all Claude Code sessions)"
  echo "  2) Local  — ./.claude/skills/ (this directory only)"
  read -r -p "Choice [1/2]: " choice
  case "$choice" in
    1) SCOPE="global" ;;
    2) SCOPE="local"  ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

# Resolve target directory
if [ "$SCOPE" = "global" ]; then
  TARGET_DIR="${HOME}/.claude/skills/${SKILLS_DIR_NAME}"
else
  TARGET_DIR="./.claude/skills/${SKILLS_DIR_NAME}"
fi

# Uninstall path
if $UNINSTALL; then
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Skills not found at ${TARGET_DIR}. Nothing to uninstall."
    exit 0
  fi
  read -r -p "Remove ${TARGET_DIR}? [y/N] " confirm
  case "$confirm" in
    [yY])
      rm -rf "$TARGET_DIR"
      echo "✅ Uninstalled from ${TARGET_DIR}."
      ;;
    *)
      echo "Uninstall cancelled."
      ;;
  esac
  exit 0
fi

# If skills/ directory is not next to this script (e.g. running via curl | bash),
# download the repository archive from GitHub into a temp directory.
if [ ! -d "$SOURCE_DIR" ]; then
  if ! command -v curl > /dev/null 2>&1; then
    echo "Error: curl is required to download skills when running via pipe."
    echo "Clone the repository and run ./install.sh instead:"
    echo "  git clone ${REPO_URL}.git && cd ios-build-speed-skills && ./install.sh"
    exit 1
  fi

  echo "Downloading ios-build-speed-skills from GitHub..."
  TEMP_DIR="$(mktemp -d)"
  # Cleanup temp directory on exit
  trap 'rm -rf "$TEMP_DIR"' EXIT

  curl -fsSL "${REPO_URL}/archive/refs/heads/main.tar.gz" \
    | tar -xz -C "$TEMP_DIR" --strip-components=1

  SOURCE_DIR="${TEMP_DIR}/skills"
fi

# Verify source directory contains the collection manifest
if [ ! -f "${SOURCE_DIR}/ios-build-speed/SKILL.md" ]; then
  echo "Error: Collection manifest not found at ${SOURCE_DIR}/ios-build-speed/SKILL.md."
  exit 1
fi

# Conflict check
if [ -d "$TARGET_DIR" ] && ! $FORCE; then
  read -r -p "Skills already installed at ${TARGET_DIR}. Overwrite? [y/N] " confirm
  case "$confirm" in
    [yY]) ;;
    *)
      echo "Installation cancelled."
      exit 0
      ;;
  esac
fi

# Warn if local install and not in a git repo
if [ "$SCOPE" = "local" ]; then
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Warning: current directory is not a git repository."
    echo "Skills that modify files (apply with confirmation mode) will not work"
    echo "until they are run inside a git repository."
    echo ""
  fi
fi

# Install
mkdir -p "$TARGET_DIR"
cp "${SOURCE_DIR}/ios-build-speed/SKILL.md" "$TARGET_DIR/SKILL.md"
cp -r "${SOURCE_DIR}/references" "$TARGET_DIR/references"
cp -r "${SOURCE_DIR}/core"       "$TARGET_DIR/core"

echo "✅ ios-build-speed skills installed to ${TARGET_DIR}."
echo ""
echo "Next: restart Claude Code to activate."
echo ""
echo "Available skill: ios-build-speed"
echo ""
echo "💡 To enable natural language triggers, add to your project's CLAUDE.md:"
echo "   See: ${SOURCE_DIR}/CLAUDE.md.example"
