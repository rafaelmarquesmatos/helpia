#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/rafaelmarquesmatos/helpia.git"
dest="${HOME}/.local/share/helpia"
bin_dir="${HOME}/.local/bin"
target="$bin_dir/helpia"

missing=()
for cmd in bash curl jq git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done
if ((${#missing[@]})); then
  echo "faltam comandos: ${missing[*]}" >&2
  exit 1
fi

if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$dest/.git" ]]; then
    root="$dest"
  elif [[ -e "$dest" ]]; then
    echo "já existe e não é uma instalação do helpia: $dest" >&2
    exit 1
  else
    git clone --depth 1 "$repo_url" "$dest"
    root="$dest"
  fi
fi

chmod +x "$root/helpia" "$root/src/main.sh"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/helpia"
mkdir -p "$config_dir"

if [[ ! -f "$config_dir/env" ]]; then
  if [[ -f "$root/.env" ]]; then
    cp "$root/.env" "$config_dir/env"
  else
    cp "$root/.env.example" "$config_dir/env"
  fi
fi
if [[ ! -s "$config_dir/provider" ]]; then
  printf '%s\n' openrouter > "$config_dir/provider"
fi
if [[ ! -s "$config_dir/model" ]]; then
  printf '%s\n' inception/mercury-2.5 > "$config_dir/model"
fi

mkdir -p "$bin_dir"
ln -sfn "$root/helpia" "$target"

echo "instalado: $target"

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *)
    echo "adicione isto ao seu shell e abra um terminal novo:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac
