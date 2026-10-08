---
name: template-standards
description: >
  Fonte central de verdade para os templates oficiais de desenvolvimento
  deste ambiente (Python CLI, .NET Web API DDD, .NET Web API SOLID, Blazor
  .NET 10, React + Vite). Use esta skill SEMPRE, antes de escrever qualquer
  código estrutural de um projeto, feature ou módulo novo — scaffold
  inicial, organização de pastas, camadas, padrões de injeção de
  dependência, nomenclatura. Consulte também sempre que estiver decidindo
  COMO implementar algo dentro de um projeto que já foi criado a partir de
  um desses templates (adicionar dependência, criar camada, seguir um
  padrão de erro/log/config/autenticação já estabelecido), mesmo que o
  usuário não mencione "template" explicitamente. Os templates são pacotes
  publicados (NuGet, npm, PyPI) e devem ser instanciados sempre pelo
  mecanismo oficial de scaffolding (`dotnet new`, `npm create`, `pipx run`)
  — esta skill também é o lugar certo para lembrar disso antes de clonar um
  repositório ou copiar arquivos manualmente para montar a estrutura de um
  projeto novo.
---

# Templates oficiais — fonte de verdade estrutural

Antes de criar qualquer código estrutural de um projeto, feature ou módulo novo, identifique a tecnologia envolvida e consulte o template oficial correspondente. Nunca invente uma arquitetura alternativa quando já existe um template oficial para o caso — a padronização entre projetos só funciona se todos partirem do mesmo lugar.

## Templates oficiais e como instanciá-los

Os templates são pacotes publicados, não repositórios para clonar. Cada um tem um mecanismo oficial de scaffolding:

| Tecnologia | Chave | Instalação (se houver) | Comando de scaffold |
|---|---|---|---|
| Python CLI | `python-cli` | — (execução efêmera via pipx) | `pipx run create-gentilpedro-python <nome>` |
| .NET Web API — DDD | `dotnet-api-ddd` | `dotnet new install GentilPedro.Templates.ApiDdd` | `dotnet new api-ddd -n <Nome>` |
| .NET Web API — SOLID | `dotnet-api-solid` | `dotnet new install GentilPedro.Templates.ApiSolid` | `dotnet new api-solid -n <Nome>` |
| Blazor .NET 10 | `dotnet-blazor10` | `dotnet new install GentilPedro.Templates.Blazor10` | `dotnet new blazor10 -n <Nome>` |
| React + Vite | `react-vite` | — (via npm create) | `npm create gentilpedro-react@latest <nome>` |

Os repositórios-fonte desses templates existem no GitHub (`github.com/gentilpedro/template-*`), mas eles não são a via de consumo — são de onde os pacotes publicados (NuGet/npm/PyPI) são construídos. Trabalhar a partir do pacote publicado garante que você está usando a versão que o mantenedor efetivamente lançou, com o versionamento e o empacotamento corretos; clonar o repositório-fonte contorna isso.

### Regra central: sempre o mecanismo oficial, nunca reconstrução manual

- **Nunca clone** os repositórios-fonte dos templates para copiar arquivos de lá.
- **Nunca copie** arquivos de outro projeto tentando reproduzir de memória a estrutura de um template.
- **Nunca reconstrua manualmente** pastas e arquivos tentando imitar o que você lembra ou supõe que o template contém.
- **Sempre gere** o projeto — ou, quando for só para consulta, uma cópia de referência descartável (ver seção abaixo) — rodando o comando oficial de scaffold da tabela acima.

O motivo não é burocracia: reconstruir manualmente inevitavelmente diverge em algum detalhe (uma dependência de versão específica, um arquivo de configuração, uma convenção de nomenclatura), e essa divergência silenciosa é exatamente o tipo de problema que padronizar templates deveria evitar.

### Ambiguidade .NET API: DDD ou SOLID?

Existem dois templates oficiais para .NET Web API. Se o usuário não especificar qual arquitetura quer (ou não estiver claro pelo contexto do projeto — ex.: um projeto que já existe e claramente segue um dos dois padrões), pergunte antes de escolher. Não assuma um dos dois por padrão — são duas arquiteturas legitimamente diferentes, e escolher a errada significa retrabalho estrutural depois.

## Criando um projeto novo

1. Identifique a tecnologia (e, para .NET API, confirme DDD ou SOLID).
2. Rode o comando de instalação do template, se houver (`dotnet new install ...`; Python e React não precisam de instalação separada).
3. Rode o comando de scaffold apontando para o nome/diretório real do projeto.
4. A partir daqui, o projeto gerado é a fonte de verdade do desenvolvimento — não é mais o template, é o projeto.

**Nunca reexecute o comando de scaffold em cima de um projeto real já existente.** Rodar `dotnet new api-ddd -n <Nome>` (ou qualquer um dos outros comandos) de novo dentro de um diretório que já é um projeto de verdade pode sobrescrever arquivos e histórico de trabalho — trate isso com a mesma cautela que um comando destrutivo. Se a intenção for "atualizar para a versão mais nova do template", isso é uma decisão que precisa de autorização explícita do desenvolvedor e de um plano de migração deliberado, não um re-scaffold por cima.

Depois que o projeto existir, siga `git-standards` para inicializar o Git com a identidade correta e `github-cicd` para configurar o pipeline — esta skill cobre só a parte estrutural/arquitetural.

## Consultando o template como referência (sem criar um projeto de verdade)

Às vezes você precisa só entender os padrões do template — não criar um projeto novo. Por exemplo: comparar um projeto já existente com a versão atual do template para checar se ele divergiu, ou entender como o template estrutura autenticação antes de implementar uma feature nova em um projeto que já usa esse template.

Para isso, gere uma **cópia de referência descartável**, usando o mesmo comando oficial de scaffold, mas apontando para um diretório temporário fora do projeto real — nunca para o projeto de verdade. O script `scripts/scaffold_reference.sh` faz isso:

```bash
scripts/scaffold_reference.sh <chave-da-tecnologia> <NomeTemporario>
```

Ele instala o template (se aplicável), roda o scaffold dentro de um diretório `mktemp`, e imprime o caminho da cópia gerada. Inspecione essa cópia — leia o README, veja a estrutura de pastas, os padrões de nomenclatura, as dependências (`.csproj`/`package.json`/`pyproject.toml`), e os exemplos de código já presentes — e descarte-a (`rm -rf`) quando terminar. Essa cópia nunca deve ser commitada, movida para virar o projeto real, ou tratada como algo além de uma referência temporária.

### Se a ferramenta oficial não estiver disponível no ambiente atual

Se o comando necessário (`dotnet`, `npm`, `pipx`) não existir no ambiente onde você está rodando — por exemplo, um ambiente sem o .NET SDK instalado — a resposta correta continua sendo não reconstruir manualmente por suposição. Em vez disso, nesta ordem de preferência: (1) veja se dá para instalar a ferramenta faltante no ambiente atual; (2) se não der, diga isso claramente ao desenvolvedor e peça para ele rodar o comando de scaffold no ambiente dele e compartilhar o resultado (ex.: colar a estrutura de pastas, ou anexar o projeto gerado); (3) como último recurso, prossiga só com o que já é possível confirmar sem o template (padrões já visíveis no projeto existente, requisitos explícitos do desenvolvedor) e marque explicitamente como pendente qualquer parte que dependeria de consultar o template.

## Se o projeto já foi criado a partir de um template

A estrutura existente do projeto é a autoridade local — não é necessário reconsultar o template para cada feature nova; geralmente basta seguir os padrões já presentes no próprio projeto. Gere uma cópia de referência (seção acima) apenas quando:

- não houver, dentro do projeto atual, nenhum exemplo equivalente ao que você está implementando; ou
- você suspeitar que o projeto divergiu da versão atual do template e quiser confirmar isso antes de agir.

### Divergências entre o projeto e o template

Se ao comparar você encontrar uma divergência entre o projeto e o template oficial: informe a divergência ao desenvolvedor, explique o impacto dela, e **não reestruture o projeto inteiro sem autorização explícita**. Nunca faça uma migração arquitetural silenciosa — trocar um padrão porque a versão atual do template mudou, sem que o desenvolvedor tenha pedido isso, tira dele o controle sobre uma decisão que é dele.

## Não copie cegamente — adapte

O template é uma referência arquitetural e estrutural, não um molde a ser aplicado sem pensar. Adapte-o ao projeto atual sem destruir padrões que já existam nele. Isso vale tanto na hora de criar o projeto (ajustar nome, namespace, configuração inicial) quanto na hora de usar o template como referência para uma feature nova.

## Dependências e escolhas tecnológicas

- Não adicione uma biblioteca só porque ela está disponível no template. Dependências entram no projeto quando são necessárias para a feature em questão, não porque "o template já tem".
- Não substitua uma tecnologia já em uso no projeto por uma alternativa apenas por preferência pessoal — nem a sua, nem a de um template mais novo.

## O que preservar num projeto existente

Ao trabalhar dentro de um projeto que já foi criado a partir de um template, preserve o que já está estabelecido, mesmo que o template oficial tenha evoluído desde então:

nomenclatura (naming), estrutura de diretórios, padrões de injeção de dependência, padrões de configuração, logging, tratamento de erros, validação, autenticação, organização dos testes, e convenções de código já em uso.

## Como resolver dúvidas de implementação

Quando houver dúvida sobre como implementar uma feature nova:

1. Procure primeiro um exemplo equivalente já existente — no próprio projeto, ou (se não houver) numa cópia de referência do template.
2. Se não houver exemplo equivalente em lugar nenhum, derive a implementação dos padrões já em uso no projeto/template (mesma forma de organizar camadas, mesmo estilo de nomenclatura, mesmo padrão de tratamento de erro), em vez de introduzir um estilo novo.
3. Antes de considerar a implementação concluída, valide-a contra o template: ela se encaixa no que já existe, ou parece um corpo estranho dentro do projeto?

## Prioridade das regras

Quando houver conflito entre estas diretrizes, resolva nesta ordem:

1. **Segurança** — nunca comprometida por nenhuma das regras abaixo.
2. **Requisitos explícitos do projeto** — o que o desenvolvedor pediu explicitamente para esta tarefa.
3. **Padrões existentes do projeto** — como o projeto já faz as coisas, mesmo que o template atual sugira diferente.
4. **Template oficial correspondente** — a referência arquitetural quando não há padrão local nem requisito explícito que já resolva a questão.
5. **Boas práticas gerais** — quando nem o projeto nem o template cobrem o caso.
6. **Preferências pessoais do agente** — a menor prioridade de todas; não é motivo para nenhuma decisão estrutural.

Nunca force o template contra um requisito explícito do projeto — se o desenvolvedor pediu algo que diverge do template oficial, o pedido dele vence, mas vale mencionar a divergência para que a decisão seja consciente, não silenciosa.

## Reconhecimento automático da tecnologia

| Sinal no projeto | Template |
|---|---|
| Python CLI, `pyproject.toml`/`setup.py` com `console_scripts`, sem framework web | `template-python-cli` |
| .NET Web API com camadas Domain/Application/Infrastructure explícitas | `template-dotnet-api-ddd` |
| .NET Web API organizada por responsabilidade única por classe/serviço, sem separação em camadas DDD | `template-dotnet-api-solid` |
| Projeto Blazor visando .NET 10 | `template-dotnet-blazor10` |
| `package.json` com `vite` + React nas dependências | `template-react-vite` |

Se o sinal não for claro (por exemplo, um .NET Web API sem estrutura ainda, recém-criado), pergunte qual arquitetura o desenvolvedor quer antes de escolher.

## Esta skill não modifica os templates

O papel desta skill é consultar e instanciar os templates oficiais — nunca alterar os pacotes publicados nem os repositórios-fonte deles. Se você notar algo que parece um problema no próprio template (um exemplo desatualizado, uma dependência quebrada), informe o desenvolvedor em vez de tentar corrigir o template a partir daqui.
