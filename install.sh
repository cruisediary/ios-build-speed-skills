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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/skills"

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

# Verify source directory exists and contains skill files
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: skills/ directory not found at ${SOURCE_DIR}."
  echo "Make sure you are running this script from the ios-build-speed-skills repository root."
  exit 1
fi

shopt -s nullglob
skill_files=( "${SOURCE_DIR}"/*.md )
shopt -u nullglob
if [ ${#skill_files[@]} -eq 0 ]; then
  echo "Error: No skill files found in ${SOURCE_DIR}."
  echo "Make sure you are running this script from the ios-build-speed-skills repository root."
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
cp -r "${SOURCE_DIR}/"* "$TARGET_DIR/"

echo "✅ ios-build-speed skills installed to ${TARGET_DIR}."
echo ""
echo "Next: restart Claude Code to activate."
echo ""
echo "Available skills:"
shopt -s nullglob
skills=( "${SOURCE_DIR}"/*.md )
shopt -u nullglob
if [ ${#skills[@]} -eq 0 ]; then
  echo "  (no skills found in ${SOURCE_DIR})"
else
  for skill in "${skills[@]}"; do
    name="$(basename "$skill" .md)"
    echo "  /${name}"
  done
fi
