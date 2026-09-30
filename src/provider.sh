#!/usr/bin/env bash

_provider_list="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/providers"

provider_known() {
  local name="$1"
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" == "$name" ]] && return 0
  done < "$_provider_list"
  return 1
}

provider_key_var() {
  case "$1" in
    openrouter) printf '%s\n' OPENROUTER_API_KEY ;;
    *) return 1 ;;
  esac
}

ask() {
  local provider="$1"
  local model="$2"
  local system="$3"
  local text="$4"

  case "$provider" in
    openrouter)
      raw="$(curl -sS -w $'\n%{http_code}' https://openrouter.ai/api/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        --data "$(jq -n --arg system "$system" --arg text "$text" --arg model "$model" '{
          model: $model,
          messages: [
            {role: "system", content: $system},
            {role: "user", content: $text}
          ]
        }')")" || return 1
      code="${raw##*$'\n'}"
      body="${raw%$'\n'*}"
      if [[ "$code" != 2* ]]; then
        message="$(jq -r '.error.message // empty' <<<"$body" 2>/dev/null || true)"
        if [[ -n "$message" ]]; then
          echo "$message" >&2
        else
          echo "$body" >&2
        fi
        return 1
      fi
      answer="$(jq -r '
        (.choices[0].message.content // "")
        | if type == "string" then sub("^\n+"; "") else "" end
      ' <<<"$body")"
      if [[ -z "$answer" ]]; then
        echo "o modelo não retornou mensagem" >&2
        return 1
      fi
      printf '%s\n' "$answer"
      ;;
    *)
      echo "provedor indisponível: $provider" >&2
      return 1
      ;;
  esac
}
