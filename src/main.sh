#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

set -a
source "$root/.env"
set +a

source "$root/src/provider.sh"

provider_file="$root/.provider"
provider="$(cat "$provider_file" 2>/dev/null || true)"
provider="${provider:-openrouter}"

model_file="$root/.model"
model="$(cat "$model_file" 2>/dev/null || true)"
model="${model:-inception/mercury-2.5}"

save_env_var() {
  local file="$1" name="$2" value="$3"
  local tmp line quoted
  quoted="${value//\'/\'\\\'\'}"
  tmp="${file}.tmp"
  if [[ -f "$file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "${name}="* ]]; then
        printf "%s='%s'\n" "$name" "$quoted"
      else
        printf '%s\n' "$line"
      fi
    done < "$file" > "$tmp"
    if ! grep -q "^${name}=" "$file"; then
      printf "%s='%s'\n" "$name" "$quoted" >> "$tmp"
    fi
  else
    printf "%s='%s'\n" "$name" "$quoted" > "$tmp"
  fi
  mv "$tmp" "$file"
}

ensure_api_key() {
  local provider="$1"
  local var key
  var="$(provider_key_var "$provider")" || {
    echo "provedor indisponível: $provider" >&2
    exit 1
  }
  if [[ -n "${!var:-}" ]]; then
    return 0
  fi
  read -r -s -p "informe a API key de ${provider}: " key
  echo
  if [[ -z "$key" ]]; then
    echo "API key vazia" >&2
    exit 1
  fi
  save_env_var "$root/.env" "$var" "$key"
  export "${var}=${key}"
}

case "${1:-}" in
  --provider)
    if [[ -z "${2:-}" ]]; then
      echo "$provider"
      exit 0
    fi
    if ! provider_known "$2"; then
      echo "provedor indisponível: $2" >&2
      echo "disponíveis: $(paste -sd ' ' "$_provider_list")" >&2
      exit 1
    fi
    printf '%s\n' "$2" > "$provider_file"
    exit 0
    ;;
  --model)
    if [[ -z "${2:-}" ]]; then
      echo "$model"
      exit 0
    fi
    printf '%s\n' "$2" > "$model_file"
    exit 0
    ;;
esac

system="$(cat "$root/prompts/system.md")

Current directory: ${PWD}
$(ls)"
text="${1:?informe uma string}"

ensure_api_key "$provider"
ask "$provider" "$model" "$system" "$text"
