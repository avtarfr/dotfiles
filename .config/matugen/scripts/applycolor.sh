#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/matugen"
STATE_DIR="$XDG_STATE_HOME/matugen"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100

if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi

if [ ! -f "$STATE_DIR/user/generated/material_colors.scss" ]; then
  echo "material_colors.scss not found"
  exit 1
fi

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat "$STATE_DIR/user/generated/material_colors.scss" | cut -d: -f1)
colorstrings=$(cat "$STATE_DIR/user/generated/material_colors.scss" | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)
colorvalues=($colorstrings)

apply_kitty() {  
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  done

  # Reload running kitty instances
  if pgrep -f kitty >/dev/null; then
    kill -SIGUSR1 $(pidof kitty) 2>/dev/null || true
  fi
}

apply_anyterm() {
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
        cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  apply_anyterm &
  apply_kitty &
}

apply_term
wait
