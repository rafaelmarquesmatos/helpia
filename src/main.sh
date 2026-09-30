#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
  helpia "pergunta"            faz uma pergunta
  helpia --provider            mostra o provedor atual
  helpia --provider <nome>     troca o provedor
  helpia --model               mostra o modelo atual
  helpia --model <nome>        troca o modelo
  helpia --help                lista os comandos
  helpia --update              atualiza o helpia
EOF
}

case "${1:-}" in
  "")
    usage >&2
    exit 1
    ;;
  -h|--help)
    usage
    exit 0
    ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/helpia"
mkdir -p "$config_dir"

env_file="$config_dir/env"
provider_file="$config_dir/provider"
model_file="$config_dir/model"

if [[ ! -f "$env_file" ]]; then
  if [[ -f "$root/.env" ]]; then
    cp "$root/.env" "$env_file"
  else
    printf '%s\n' 'OPENROUTER_API_KEY=' > "$env_file"
  fi
fi
if [[ ! -s "$provider_file" ]]; then
  if [[ -s "$root/.provider" ]]; then
    cp "$root/.provider" "$provider_file"
  else
    printf '%s\n' openrouter > "$provider_file"
  fi
fi
if [[ ! -s "$model_file" ]]; then
  if [[ -s "$root/.model" ]]; then
    cp "$root/.model" "$model_file"
  else
    printf '%s\n' inception/mercury-2.5 > "$model_file"
  fi
fi

set -a
source "$env_file"
set +a

source "$root/src/provider.sh"

provider="$(cat "$provider_file" 2>/dev/null || true)"
provider="${provider:-openrouter}"

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
  save_env_var "$env_file" "$var" "$key"
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
  --update)
    if [[ ! -d "$root/.git" ]]; then
      echo "esta cópia não pode ser atualizada pelo git" >&2
      exit 1
    fi
    install_dir="$(cd "${HOME}/.local/share/helpia" 2>/dev/null && pwd || true)"
    git -C "$root" fetch origin
    if [[ -n "$install_dir" && "$root" == "$install_dir" ]]; then
      git -C "$root" reset --hard origin/main
    else
      git -C "$root" pull --ff-only
    fi
    exit 0
    ;;
  -*)
    usage >&2
    exit 1
    ;;
esac

system="$(cat "$root/prompts/system.md")

Current directory: ${PWD}
$(ls)"
text="$1"

ensure_api_key "$provider"
ask "$provider" "$model" "$system" "$text"
