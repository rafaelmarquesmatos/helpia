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
    git -C "$dest" pull --ff-only
  else
    git clone --depth 1 "$repo_url" "$dest"
  fi
  root="$dest"
fi

chmod +x "$root/helpia" "$root/src/main.sh"

if [[ ! -f "$root/.env" ]]; then
  cp "$root/.env.example" "$root/.env"
fi

if [[ ! -s "$root/.provider" ]]; then
  printf '%s\n' openrouter > "$root/.provider"
fi

if [[ ! -s "$root/.model" ]]; then
  printf '%s\n' inception/mercury-2.5 > "$root/.model"
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
