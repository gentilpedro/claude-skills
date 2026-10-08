---
name: python-cli
description: >
  Especializada em desenvolvimento e manutenção de CLIs Python do template
  create-gentilpedro-python. Use sempre que for criar/alterar comandos,
  argumentos, opções, configuração, validação, tratamento de erro, ou
  integração com API/arquivos num projeto CLI Python já criado a partir
  desse template — mesmo sem o usuário dizer "CLI", bastando "adiciona um
  comando pra X" ou "corrige esse bug no comando Y". Consulte também antes
  de usar `subprocess`/`shell=True`, `except Exception: pass`, `pickle`
  com dado externo, `Any` sem justificativa, ou adicionar dependência
  nova. NÃO usar para criar projeto novo (`template-standards`), Git
  (`git-standards`), CI/CD (`github-cicd`), ou release
  (`release-standards`) — foco exclusivo na CLI Python.
---

# CLI Python (template create-gentilpedro-python)

Esta skill assume que o projeto já existe, criado a partir do template `create-gentilpedro-python` (`pipx run create-gentilpedro-python <nome>` ou `uvx create-gentilpedro-python <nome>`, fonte em `github.com/gentilpedro/template-python-cli`). Ela não cria projetos novos — isso é `template-standards`; nunca clone o repositório, copie arquivos manualmente, reconstrua a estrutura, ou substitua o template por outro boilerplate. Depois que o projeto existe, a estrutura local é a fonte de verdade, e esta skill governa as decisões de implementação dentro dela.

## Python e tipagem

Use a versão de Python definida pelo projeto — verifique o `pyproject.toml` antes de qualquer suposição, e não atualize a versão só por preferência pessoal.

Use type hints em código novo. Evite `Any` sem justificativa, e evite casts desnecessários. Prefira type hints simples, `Protocol`, `TypedDict`, `dataclass` e generics quando eles realmente agregam valor — não crie tipos complexos para código trivial; um `dataclass` de dois campos simples não precisa de um `Protocol` genérico em volta.

## Estrutura

Respeite a estrutura criada pelo template; não reorganize diretórios sem necessidade real. Quando o projeto separar responsabilidades em camadas — `CLI → Application → Domain/Services → Infrastructure` —, respeite essa separação. Não coloque a aplicação inteira dentro do arquivo da CLI.

## Camada CLI

A CLI é a interface com o usuário: recebe argumentos e opções, valida entrada básica, chama a aplicação, apresenta resultados, apresenta erros de forma apropriada, e retorna o exit code correto. Ela **não** contém a regra de negócio — isso pertence à Application/Domain. Evite comandos gigantes que fazem tudo dentro do handler do comando.

### Comandos

Cada comando tem responsabilidade clara (`create`, `list`, `get`, `delete`, `update`, `config`...). Não crie um único comando com dezenas de comportamentos condicionais dependendo de flags — quando um comando cresce demais, avalie separar em subcomandos.

### Argumentos e opções

Diferencie argumentos obrigatórios de opções opcionais, e escreva mensagens de ajuda claras. Não force o usuário a memorizar um comportamento implícito que não está documentado no `--help`.

### Exit codes

A CLI retorna exit codes coerentes: `0` para sucesso, diferente de zero para falha. **Nunca retorne `0` quando ocorreu um erro** — isso é especialmente importante porque scripts, pipelines de CI/CD e automações decidem o que fazer a seguir com base no exit code, não lendo a mensagem de texto.

### stdout / stderr

Separe stdout de stderr: resultado normal vai para stdout, erro vai para stderr quando apropriado. Não misture log de diagnóstico com saída destinada a ser consumida por outro programa sem necessidade — se a CLI tem uma opção de saída estruturada (ex.: `--json`), considere formatos como JSON só quando isso realmente fizer sentido para o comando, e não altere o formato de saída já existente sem necessidade (scripts de terceiros podem depender do formato atual).

## Configuração

Configuração pode vir de argumentos, opções, variáveis de ambiente, arquivo de configuração, ou defaults — defina a precedência entre essas fontes de forma previsível e documentada. Não espalhe leitura de `os.environ` por dezenas de módulos; centralize a configuração num só lugar quando fizer sentido.

## Secrets

Nunca armazene senha, API key, token, chave privada, ou connection string sensível diretamente no código. Nunca commite secrets. Use variáveis de ambiente ou um mecanismo seguro equivalente. Nunca imprima um secret no terminal — nem em modo debug, nem "só para conferir".

## API / HTTP

Ao consumir uma API: use o cliente HTTP já existente no projeto quando houver um, respeite timeout, trate erro HTTP, trate timeout, trate falha de conexão, valide a resposta, evite chamadas desnecessárias. Não espalhe código HTTP pelos comandos — prefira `CLI → Application/Service → HTTP Client → API`.

## Arquivos e diretórios

Use `pathlib.Path` em vez de concatenação de strings ou `os.path` em código novo. Trate arquivo inexistente e problemas de permissão explicitamente; use encoding explícito quando apropriado; evite carregar um arquivo gigante inteiro na memória sem necessidade.

Não assuma que o usuário sempre vai executar a CLI no diretório "certo". Resolva paths de forma robusta, e não use `os.getcwd()` como base de tudo sem entender o contexto — diferencie o diretório de trabalho atual (de onde o comando foi chamado) do diretório de configuração da aplicação (onde ela guarda seus próprios dados), porque são conceitos diferentes mesmo quando coincidem na maioria dos casos.

## Logging

Use o mecanismo de logging já existente no projeto (tipicamente `logging` da standard library). Não use `print()` como mecanismo de log interno — `print()` é apropriado para a saída explícita da CLI (o resultado que o usuário pediu), não para diagnóstico interno. Logs têm contexto útil, mas nunca registram senha, token, API key, secret, ou dado sensível desnecessário.

## Tratamento de exceções

Nunca use `except Exception: pass` — isso esconde erro, não trata. Exceções são tratadas no nível correto: a camada de domínio/aplicação pode lançar exceções específicas do domínio; a camada CLI converte essas exceções em mensagem adequada + exit code adequado. Não mostre stack trace para o usuário final em condições normais — disponibilize stack trace num modo debug explícito (`--debug`/`-v`), não por padrão.

Crie exceções customizadas quando elas representam um erro relevante para o domínio ou a aplicação — não crie uma classe de exceção para cada erro trivial só por criar.

## Async e concorrência

Use `async` quando há I/O assíncrono real; não o use artificialmente, e não misture código síncrono e assíncrono sem entender o event loop (bloquear dentro de uma corrotina anula o benefício de ser assíncrona). Não introduza threads, processos, ou `asyncio` só por preferência — primeiro entenda volume, tipo de I/O, uso de CPU, e se há necessidade real de paralelismo. Prefira execução sequencial simples quando ela já é suficiente.

## Dependências

Antes de adicionar um pacote: verifique o `pyproject.toml` → verifique as dependências já existentes → verifique se a standard library (`pathlib`, `json`, `argparse`, `logging`, etc.) já resolve → avalie manutenção do pacote → avalie segurança → só então adicione, se necessário. Não instale uma biblioteca para resolver algo que a standard library já resolve adequadamente.

## Formatação e lint — sempre via `pyproject.toml`

Verifique as ferramentas configuradas no projeto antes de rodar qualquer comando — não invente ferramenta. Se o projeto usa Ruff, use Ruff; se usa Black, use Black; se usa outra coisa, respeite o que já está configurado. Não desabilite uma regra de lint só para o lint passar — se uma regra realmente não se aplica a um caso específico, justifique a exceção explicitamente (comentário `# noqa` com o motivo, por exemplo), não silencie sem explicação.

(O script `scripts/quality_gate.sh` desta skill detecta Ruff/pytest/empacotamento configurados no `pyproject.toml` e roda só o que está configurado — sem chutar comando.)

## Testes

Use o framework de testes já existente no projeto — se é pytest, use pytest; não troque de framework sem solicitação. Teste comportamento, não implementação interna. Prioridade: comandos, regras de negócio, validações, services, integração crítica, tratamento de erro.

### Testando a CLI

Quando apropriado, teste: comando válido, argumento inválido, opção inválida, exit code, stdout, stderr, tratamento de exceção, arquivo inexistente, API indisponível. Uma CLI deve ser testada como o usuário realmente a executa — invocando o comando e verificando saída/exit code, não só chamando a função interna diretamente.

## Bugfix

Ao corrigir um bug: reproduza → identifique a causa → crie teste de regressão quando apropriado → implemente a correção → execute os testes → execute o lint → revise o impacto. Corrija a causa, não só o sintoma, quando a causa puder ser identificada — um `try/except` que engole o sintoma sem entender a causa tende a voltar em outra forma depois.

## Segurança

Avalie, ao implementar qualquer funcionalidade: command injection, path traversal, secrets, arquivos temporários, permissões, URLs externas, validação de input, SSRF (quando a CLI consome uma URL fornecida pelo usuário), e execução de comandos externos.

**Nunca** execute comando de sistema construindo a string diretamente com input do usuário:

```python
# NUNCA:
subprocess.run(f"comando {user_input}", shell=True)
```

Prefira sempre argumentos separados, sem shell:

```python
subprocess.run(["comando", "argumento"], check=True)
```

Evite `shell=True` quando não for estritamente necessário. Nunca passe input externo direto para um shell sem validação rigorosa. Valide paths fornecidos pelo usuário quando houver risco de path traversal (ex.: um argumento `--output ../../etc/passwd`).

## Serialização

Use `json` da standard library quando ele já resolve. Nunca use `pickle` para desserializar dado não confiável — `pickle.loads` em dado externo é execução de código arbitrário, não um formato de dados seguro.

## Cache e performance

Não adicione cache automaticamente — só quando houver requisito real ou benefício mensurável; cache é complexidade que também pode esconder bug (dado desatualizado). Priorize algoritmo simples, I/O eficiente, evitar chamada duplicada, evitar carregar arquivo enorme na memória, evitar chamada de API desnecessária. Não otimize prematuramente.

## Documentação da CLI

Todo comando público tem help adequado — o usuário deve conseguir descobrir o que o comando faz, quais argumentos e opções existem, quais são os defaults, e exemplos quando fizer sentido, sem precisar sair da CLI para ler documentação externa (para comandos simples, pelo menos).

## Versionamento, build e empacotamento

A versão da aplicação segue o mecanismo já existente no projeto — não crie um segundo mecanismo de versionamento em paralelo. Quando uma release for necessária, siga `release-standards`; não crie release manualmente ignorando essa skill.

Antes de alterar o empacotamento, verifique o `pyproject.toml`: build backend, nome do pacote, entry points, dependências, metadata. Não modifique o sistema de build sem necessidade. A CLI usa o entry point já definido pelo projeto — não crie scripts paralelos sem necessidade; se for realmente preciso alterar o nome do comando, avalie o impacto no pacote e nos usuários existentes antes.

## Quality Gate

Uma implementação não está concluída até: o requisito estar implementado, a tipagem estar adequada, o lint passando, os testes passando, a CLI executando corretamente (teste manual do comando, não só os testes automatizados), o tratamento de erro validado, a segurança revisada, o empacotamento validado quando aplicável, as dependências revisadas, o `git diff` revisado, e o Git tratado conforme `git-standards`. "Funciona na minha máquina" não significa tarefa concluída.

## Fluxo de implementação

**Feature nova:**

1. Entender o requisito.
2. Identificar o comando afetado.
3. Identificar a camada responsável.
4. Verificar código existente reutilizável.
5. Implementar.
6. Adicionar validação.
7. Adicionar tratamento de erro.
8. Adicionar testes.
9. Verificar os tipos.
10. Executar o lint.
11. Executar os testes.
12. Validar a execução real da CLI.
13. Validar o empacotamento quando aplicável.
14. Revisar segurança.
15. Revisar o `git diff`.
16. Seguir `git-standards` (branch `feature/<descricao>`).

**Correção de bug:**

1. Reproduzir.
2. Identificar a causa.
3. Criar teste de regressão.
4. Corrigir.
5. Executar os testes.
6. Executar o lint.
7. Validar a CLI.
8. Validar o empacotamento quando aplicável.
9. Revisar segurança.
10. Seguir `git-standards` (branch `bugfix/<descricao>`).

## Regra de conservadorismo

Prefira a standard library do Python + as dependências já existentes + a estrutura do template, antes de adicionar uma biblioteca nova. Não crie abstração desnecessária, classe artificial, framework desnecessário, camada excessiva, ou dependência por preferência pessoal. Código Python aqui é: simples, legível, tipado, testável, seguro, manutenível — nessa ordem de prioridade quando duas dessas qualidades competirem.

## O que esta skill NÃO faz — e quem faz

- **Criar o projeto**: `template-standards` — nunca clone o repositório do template nem reconstrua a estrutura manualmente aqui.
- **Operações de Git**: `git-standards`. Não duplicado aqui — só reforça `feature/<descricao>` e `bugfix/<descricao>`, nunca direto na branch principal.
- **CI/CD**: `github-cicd`. O mínimo esperado para a pipeline é `instalação/dependências → lint → test → build/package → release quando aplicável`; não reimplementado aqui.
- **Versionamento e release**: `release-standards`.

## Princípio final

A CLI deve ser simples de usar e simples de manter. Uma boa CLI funciona bem tanto para uso humano quanto para automação, scripts e CI/CD — por isso exit codes corretos, stdout/stderr corretos, mensagens claras, e comandos previsíveis não são detalhes de polimento: são parte do contrato da aplicação, tão importantes quanto o comportamento funcional em si.
