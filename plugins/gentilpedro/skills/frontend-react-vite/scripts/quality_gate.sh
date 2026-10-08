#!/usr/bin/env bash
# quality_gate.sh — cobre a parte automatizável do Quality Gate desta
# skill: install -> lint -> test -> build, SEMPRE usando os scripts que o
# package.json do projeto já define (nunca um comando inventado/chutado).
# Não substitui a revisão manual de TypeScript, segurança, acessibilidade,
# estados loading/error/empty, etc. listada no SKILL.md.
#
# Uso:
#   scripts/quality_gate.sh [caminho-do-projeto]
#
# Sai com código != 0 e para imediatamente se install, lint, test ou build
# falharem — de propósito, para que a implementação nunca seja tratada
# como concluída com uma dessas etapas quebrada. Se um script (lint/test)
# não existir no package.json, a etapa é pulada com um aviso — não é
# inventado um comando genérico no lugar dele.

set -uo pipefail

TARGET="${1:-.}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; }
pass() { printf '\033[32m✓ %s\033[0m\n' "$1"; }
warn() { printf '\033[33m! %s\033[0m\n' "$1"; }

if ! command -v npm >/dev/null 2>&1; then
  fail "npm não encontrado neste ambiente."
  exit 127
fi

if [[ ! -f "$TARGET/package.json" ]]; then
  fail "Nenhum package.json encontrado em '$TARGET'."
  exit 1
fi

cd "$TARGET" || exit 1

has_script() {
  node -e "
    const pkg = require('./package.json');
    process.exit(pkg.scripts && pkg.scripts['$1'] ? 0 : 1);
  " 2>/dev/null
}

bold "== 1/4 install (npm ci) =="
if ! npm ci; then
  fail "npm ci falhou — pare aqui. A implementação NÃO está concluída."
  exit 1
fi
pass "install ok"
echo

for STEP in lint test build; do
  bold "== $STEP =="
  if has_script "$STEP"; then
    if ! npm run "$STEP"; then
      fail "'npm run $STEP' falhou — pare aqui. NÃO ignore o erro nem contorne para conseguir sucesso. A implementação NÃO está concluída."
      exit 1
    fi
    pass "$STEP ok"
  else
    if [[ "$STEP" == "build" ]]; then
      warn "Script 'build' não existe no package.json — incomum para um projeto Vite; confirme se isso é esperado."
    else
      warn "Script '$STEP' não existe no package.json — pulando (não inventar comando no lugar dele)."
    fi
  fi
  echo
done

bold "Quality gate automatizado concluído (install + lint/test/build conforme definidos no package.json)."
echo "Lembrete: isso cobre só a parte automatizável. Ainda revise TypeScript, segurança," \
     "acessibilidade, responsividade, estados loading/error/empty e o git diff antes de" \
     "considerar a implementação concluída (ver seção Quality Gate do SKILL.md)."
