#!/usr/bin/env bash
# scan_diff.sh — varredura determinística do diff atual (ou de um range
# especificado) por padrões que as seções "Secrets" e "Revisão de diff"
# do code-review pedem para nunca deixar passar: segredos aparentes e
# sobras de debug. É um primeiro filtro rápido e repetível — NÃO
# substitui a leitura humana do diff, e um match aqui não é
# automaticamente um problema real (pode ser um TODO antigo, ou uma
# string que só parece uma chave). Cada ocorrência merece confirmação
# explícita antes de aprovar o PR.
#
# Uso:
#   scripts/scan_diff.sh                  # diff do working tree (não staged)
#   scripts/scan_diff.sh --staged         # diff staged
#   scripts/scan_diff.sh main...HEAD      # diff contra a base da branch
#   scripts/scan_diff.sh main..HEAD       # idem, outra sintaxe de range

set -uo pipefail

DIFF_OUTPUT="$(git diff "$@" 2>&1)"
if [[ $? -ne 0 ]]; then
  echo "Erro ao rodar 'git diff $*':" >&2
  echo "$DIFF_OUTPUT" >&2
  exit 1
fi

if [[ -z "$DIFF_OUTPUT" ]]; then
  echo "Nenhuma alteração encontrada para o diff solicitado."
  exit 0
fi

# Só considera linhas adicionadas (prefixo '+', excluindo o cabeçalho '+++').
ADDED_LINES="$(printf '%s\n' "$DIFF_OUTPUT" | grep -E '^\+' | grep -vE '^\+\+\+')"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
hit() { printf '\033[31m  %s\033[0m\n' "$1"; }

FOUND=0

check() {
  local label="$1" pattern="$2"
  local matches
  matches="$(printf '%s\n' "$ADDED_LINES" | grep -inE -- "$pattern" || true)"
  if [[ -n "$matches" ]]; then
    FOUND=1
    bold "== $label =="
    while IFS= read -r line; do hit "$line"; done <<< "$matches"
    echo
  fi
}

bold "Varredura de diff — code-review"
echo

check "Possível secret (chave/senha/token atribuído a uma string literal)" \
  '(api[_-]?key|secret|password|passwd|token|private[_-]?key|connection[_-]?string)[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{6,}'

check "Chave de nuvem/serviço com prefixo conhecido (AWS/GitHub/Stripe)" \
  '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|sk_live_[A-Za-z0-9]{10,}|sk_test_[A-Za-z0-9]{10,})'

check "Bloco de chave privada" \
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'

check "Debug deixado no código (console.log / print / Console.WriteLine)" \
  '(console\.(log|debug)\(|^\+[[:space:]]*print\(|Console\.WriteLine\()'

check "Debugger / breakpoint esquecido" \
  '(debugger;|pdb\.set_trace\(\)|breakpoint\(\))'

check "TODO / FIXME / XXX" \
  '(TODO|FIXME|XXX)[:[:space:]]'

if [[ "$FOUND" -eq 0 ]]; then
  echo "Nenhum padrão suspeito encontrado nesta varredura automática."
  echo "Isso não substitui a leitura do diff linha a linha — só cobre os padrões óbvios."
else
  echo "Revise cada ocorrência acima antes de aprovar o PR."
fi
