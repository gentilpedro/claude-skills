#!/usr/bin/env bash
# scaffold_reference.sh — gera uma CÓPIA DE REFERÊNCIA DESCARTÁVEL de um
# template oficial, usando o mesmo mecanismo oficial de scaffolding
# (pipx/dotnet new/npm create) que seria usado para criar um projeto de
# verdade — só que apontando para um diretório temporário, nunca para o
# projeto real.
#
# Isso existe para o caso em que você precisa CONSULTAR os padrões do
# template (nomenclatura, estrutura de pastas, exemplos, dependências)
# sem estar criando um projeto novo agora — por exemplo, para comparar um
# projeto já existente com a versão atual do template. Nunca use git clone
# nem copie/reconstrua arquivos manualmente para esse fim: sempre gere a
# referência com o comando oficial.
#
# Uso:
#   scripts/scaffold_reference.sh <chave-da-tecnologia> <NomeDoProjetoTemp>
#
# Chaves aceitas: python-cli, dotnet-api-ddd, dotnet-api-solid,
#                 dotnet-blazor10, react-vite
#
# Imprime o caminho da cópia de referência em stdout ao final. Descarte o
# diretório (rm -rf) quando terminar de consultá-lo.

set -euo pipefail

KEY="${1:-}"
NAME="${2:-}"

if [[ -z "$KEY" || -z "$NAME" ]]; then
  echo "Uso: $0 <chave-da-tecnologia> <NomeDoProjetoTemp>" >&2
  echo "Chaves aceitas: python-cli dotnet-api-ddd dotnet-api-solid dotnet-blazor10 react-vite" >&2
  exit 1
fi

WORKDIR="$(mktemp -d -t "template-ref-${KEY}-XXXXXX")"
echo "Gerando cópia de referência DESCARTÁVEL em: $WORKDIR" >&2
echo "(isto NÃO é um projeto real — apenas para consulta; descarte depois)" >&2
cd "$WORKDIR"

case "$KEY" in
  python-cli)
    pipx run create-gentilpedro-python "$NAME"
    ;;
  dotnet-api-ddd)
    dotnet new install GentilPedro.Templates.ApiDdd
    dotnet new api-ddd -n "$NAME"
    ;;
  dotnet-api-solid)
    dotnet new install GentilPedro.Templates.ApiSolid
    dotnet new api-solid -n "$NAME"
    ;;
  dotnet-blazor10)
    dotnet new install GentilPedro.Templates.Blazor10
    dotnet new blazor10 -n "$NAME"
    ;;
  react-vite)
    npm create gentilpedro-react@latest "$NAME"
    ;;
  *)
    echo "Chave desconhecida: $KEY" >&2
    echo "Chaves aceitas: python-cli dotnet-api-ddd dotnet-api-solid dotnet-blazor10 react-vite" >&2
    rmdir "$WORKDIR" 2>/dev/null || true
    exit 1
    ;;
esac

echo "$WORKDIR/$NAME"
