#!/usr/bin/env bash
# quality_gate.sh — cobre a parte automatizável do Quality Gate desta
# skill: lint -> test -> build/package, detectando o que está REALMENTE
# configurado no pyproject.toml do projeto em vez de chutar uma
# ferramenta. Não substitui a revisão manual de tipagem, segurança,
# execução real da CLI, etc. listada no SKILL.md.
#
# Uso:
#   scripts/quality_gate.sh [caminho-do-projeto]
#
# Sai com código != 0 e para imediatamente se lint, test ou build
# falharem — de propósito, para que a implementação nunca seja tratada
# como concluída com uma dessas etapas quebrada. Uma etapa cuja
# ferramenta não está configurada no projeto é pulada com aviso, nunca
# substituída por um comando genérico.

set -uo pipefail

TARGET="${1:-.}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; }
pass() { printf '\033[32m✓ %s\033[0m\n' "$1"; }
warn() { printf '\033[33m! %s\033[0m\n' "$1"; }

if [[ ! -f "$TARGET/pyproject.toml" ]]; then
  fail "Nenhum pyproject.toml encontrado em '$TARGET'."
  exit 1
fi

cd "$TARGET" || exit 1

has_ruff_config() {
  [[ -f .ruff.toml || -f ruff.toml ]] || grep -qs "\[tool\.ruff" pyproject.toml
}

has_pytest_setup() {
  [[ -d tests ]] || [[ -f pytest.ini ]] || grep -qs "\[tool\.pytest" pyproject.toml
}

has_build_system() {
  grep -qs "\[build-system\]" pyproject.toml
}

bold "== lint =="
if has_ruff_config; then
  if command -v ruff >/dev/null 2>&1; then
    if ! ruff check .; then
      fail "ruff encontrou problemas — pare aqui. NÃO desabilite regras só para o lint passar; se uma regra não se aplica, justifique a exceção explicitamente. A implementação NÃO está concluída."
      exit 1
    fi
    pass "lint (ruff) ok"
  else
    fail "Ruff está configurado neste projeto (pyproject.toml/ruff.toml) mas não está instalado neste ambiente. Instale antes de continuar — não pule o lint."
    exit 1
  fi
else
  warn "Nenhuma configuração de Ruff encontrada — pulando lint (não inventando ferramenta no lugar dela)."
fi
echo

bold "== test =="
if has_pytest_setup; then
  if command -v pytest >/dev/null 2>&1; then
    if ! pytest; then
      fail "testes falharam — pare aqui. NÃO desabilite um teste para conseguir sucesso. A implementação NÃO está concluída."
      exit 1
    fi
    pass "testes (pytest) ok"
  else
    fail "Há testes/config de pytest neste projeto, mas pytest não está instalado neste ambiente. Instale antes de continuar."
    exit 1
  fi
else
  warn "Nenhum diretório tests/ nem configuração de pytest encontrada — pulando testes."
fi
echo

bold "== build/package =="
if has_build_system; then
  if python3 -c "import build" >/dev/null 2>&1; then
    if ! python3 -m build; then
      fail "empacotamento falhou — pare aqui. A implementação NÃO está concluída."
      exit 1
    fi
    pass "build/package ok"
  else
    warn "[build-system] está configurado, mas o pacote 'build' não está instalado neste ambiente (pip install build). Empacotamento não verificado."
  fi
else
  warn "Nenhum [build-system] no pyproject.toml — pulando validação de empacotamento."
fi

echo
bold "Quality gate automatizado concluído."
echo "Lembrete: isso cobre só a parte automatizável. Ainda revise tipagem, segurança," \
     "execução real da CLI (exit codes, stdout/stderr, --help) e o git diff antes de" \
     "considerar a implementação concluída (ver seção Quality Gate do SKILL.md)."
