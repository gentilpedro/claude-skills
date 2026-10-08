# claude-skills

Marketplace de plugins do Claude Code com as minhas skills pessoais: padrões de Git, revisão,
CI/CD e release, e as skills das stacks dos meus templates.

## Instalar

Os projetos criados a partir dos templates já vêm com o plugin habilitado em
`.claude/settings.json`. Ao abrir o projeto, o Claude Code pede para confiar no marketplace e
instala o plugin.

Para usar em qualquer outro projeto:

```
/plugin marketplace add gentilpedro/claude-skills
/plugin install gentilpedro@gentilpedro-skills
```

Ou, para deixar fixo num repositório, no `.claude/settings.json` dele:

```json
{
  "extraKnownMarketplaces": {
    "gentilpedro-skills": {
      "source": { "source": "github", "repo": "gentilpedro/claude-skills" }
    }
  },
  "enabledPlugins": {
    "gentilpedro@gentilpedro-skills": true
  }
}
```

## Skills

Todas ficam no plugin `gentilpedro` e aparecem como `gentilpedro:<skill>`.

| Skill | Para quê |
|---|---|
| `git-standards` | Identidade de commit, branches, revisão antes de commit/push, comandos destrutivos |
| `fluxo-issue-mr` | Fluxo issue → branch → PR (GitHub) ou MR (GitLab), sem atribuição ao Claude |
| `code-review` | Revisão transversal antes de considerar uma mudança pronta |
| `github-cicd` | CI/CD no GitHub Actions desde a criação do projeto |
| `release-standards` | SemVer, tags, changelog e GitHub Releases |
| `template-standards` | Fonte de verdade dos templates e de como instanciá-los |
| `api-dotnet-ddd` | APIs .NET 10 do template DDD |
| `api-dotnet-solid` | APIs .NET 10 do template SOLID |
| `blazor-dotnet10` | Apps Blazor .NET 10 |
| `frontend-react-vite` | Frontends React + TypeScript + Vite + Tailwind |
| `python-cli` | CLIs Python |

## Atualizar

O `plugin.json` não fixa `version`, então cada commit na `main` vale como versão nova. Nos
projetos, `/plugin marketplace update gentilpedro-skills` puxa a última versão.

## Estrutura

```
.claude-plugin/marketplace.json        catálogo do marketplace
plugins/gentilpedro/
  .claude-plugin/plugin.json           manifesto do plugin
  skills/<skill>/SKILL.md              uma pasta por skill, com scripts/ e assets/ quando houver
scripts/validar.py                     validação rodada no CI
```

Skill nova: crie `plugins/gentilpedro/skills/<nome>/SKILL.md` com `name` igual ao nome da pasta e
uma `description` que diga quando usar. Antes de subir, rode `claude plugin validate .` e
`python scripts/validar.py`.
