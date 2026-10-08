"""Valida o marketplace: manifestos JSON e frontmatter de cada SKILL.md."""
import json
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
erros: list[str] = []

marketplace = json.loads((RAIZ / ".claude-plugin/marketplace.json").read_text(encoding="utf-8"))
for plugin in marketplace["plugins"]:
    pasta = RAIZ / plugin["source"]
    manifesto = pasta / ".claude-plugin/plugin.json"
    if not manifesto.is_file():
        erros.append(f"{plugin['name']}: falta {manifesto.relative_to(RAIZ)}")
        continue
    if json.loads(manifesto.read_text(encoding="utf-8"))["name"] != plugin["name"]:
        erros.append(f"{plugin['name']}: nome diferente em plugin.json")

    for skill in sorted((pasta / "skills").iterdir()):
        arquivo = skill / "SKILL.md"
        if not arquivo.is_file():
            erros.append(f"{skill.name}: falta SKILL.md")
            continue
        texto = arquivo.read_text(encoding="utf-8")
        frontmatter = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
        if not frontmatter:
            erros.append(f"{skill.name}: SKILL.md sem frontmatter")
            continue
        nome = re.search(r"^name:\s*(\S+)", frontmatter.group(1), re.M)
        if not nome or nome.group(1) != skill.name:
            erros.append(f"{skill.name}: 'name' do frontmatter não bate com a pasta")
        if not re.search(r"^description:", frontmatter.group(1), re.M):
            erros.append(f"{skill.name}: frontmatter sem 'description'")
        print(f"ok  {plugin['name']}:{skill.name}")

for erro in erros:
    print(f"ERRO {erro}", file=sys.stderr)
sys.exit(1 if erros else 0)
