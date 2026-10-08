#!/usr/bin/env bash
# quality_gate.sh — cobre a parte automatizável do Quality Gate desta skill
# (restore -> build -> test), parando no primeiro erro e reportando
# warnings do build. Não substitui a revisão manual de arquitetura,
# Controller/Service/Repository/Domain, segurança, etc. listada no
# SKILL.md — só garante que ninguém pula restore/build/test por pressa.
#
# Uso:
#   scripts/quality_gate.sh [caminho-do-projeto-ou-solucao]
#
# Sai com código != 0 e para imediatamente se restore, build ou test
# falharem — de propósito, para que a implementação nunca seja tratada
# como concluída com uma dessas etapas quebrada.

set -uo pipefail

TARGET="${1:-.}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$1" >&2; }
pass() { printf '\033[32m✓ %s\033[0m\n' "$1"; }

if ! command -v dotnet >/dev/null 2>&1; then
  fail "dotnet não encontrado neste ambiente. Instale o .NET SDK ou rode este script onde o SDK esteja disponível — não pule restore/build/test por causa disso."
  exit 127
fi

bold "== 1/3 dotnet restore =="
if ! dotnet restore "$TARGET"; then
  fail "restore falhou — pare aqui. A implementação NÃO está concluída."
  exit 1
fi
pass "restore ok"
echo

bold "== 2/3 dotnet build =="
BUILD_LOG="$(mktemp)"
if ! dotnet build "$TARGET" --no-restore --configuration Release | tee "$BUILD_LOG"; then
  fail "build falhou — pare aqui. A implementação NÃO está concluída."
  rm -f "$BUILD_LOG"
  exit 1
fi
pass "build ok"

WARNING_COUNT=$(grep -c -E "warning [A-Z]+[0-9]+" "$BUILD_LOG" || true)
if [[ "${WARNING_COUNT:-0}" -gt 0 ]]; then
  echo
  bold "Warnings encontrados no build ($WARNING_COUNT) — revise antes de considerar a tarefa concluída:"
  grep -E "warning [A-Z]+[0-9]+" "$BUILD_LOG" | sort -u
fi
rm -f "$BUILD_LOG"
echo

bold "== 3/3 dotnet test =="
if ! dotnet test "$TARGET" --no-build --configuration Release; then
  fail "testes falharam — pare aqui. NÃO desabilite o teste para conseguir sucesso. A implementação NÃO está concluída."
  exit 1
fi
pass "testes ok"

echo
bold "Quality gate automatizado passou (restore + build + test)."
echo "Lembrete: isso cobre só a parte automatizável. Ainda revise arquitetura, Controller," \
     "Service, Repository, Domain, DTOs, validações, autenticação/autorização, segurança," \
     "logging e o git diff antes de considerar a implementação concluída (ver seção Quality" \
     "Gate do SKILL.md)."
