# Guia da API para o Mobile — execução de OS pelo técnico

Este guia explica como o **app mobile do técnico** conversará com a API.

> **Fonte original:** https://www.mdshare.online/s/xjDlOBvZISh3TZ8uPMrii  
> Se os dados abaixo divergirem do código backend, o **código tem prioridade**.

---

## Para quem é o app

O público é o **técnico de campo**, com o cargo `TÉCNICO` e as permissões:

- `LOGIN` — entra no sistema
- `ACESSO_MOBILE` — entra pelo app (header `X-Platform: mobile`)
- `EXECUTAR_SERVICOS` — usa tudo que começa com `/api/executar/`

O técnico **só vê o que foi alocado para ele**. Não existe, nesta API, "pegar OS da fila" nem gerenciar equipes.

**Fora do escopo do app:** painel de admin, pagamento, contratos.

---

## Ideia geral do app

O técnico entra no app, vê o dia, abre uma **ordem de serviço (OS)**, faz **check-in em uma etapa**, percorre os **equipamentos** (preenche checklist, completa tarefas, preenche formulários de tarefas), pede **assinatura do cliente**, **finaliza o atendimento** e, se todas as etapas estiverem finalizadas, **finaliza a OS**.

Não há endpoint de sincronização (`POST /sync`). A ideia é que o app possa salvar localmente o checklist e formulários de tarefas (formulários offline), mas **qualquer mudança de status dos recursos exigem internet (check-in, completar tarefas, etc)**.

---

## Conceitos (o vocabulário do produto)

| No app / no dia a dia | Na API | O que é |
|----------------------|--------|---------|
| Serviço / OS | `Servico` | O trabalho como um todo (`OS-202609-AB12`) |
| Atendimento / visita | `Etapa` | Um recorte da OS no tempo (ex.: manhã no cliente X) |
| Equipamento da OS | `EquipamentoServico` | Ligação entre um aparelho e aquela OS — **não** é o `id` do cadastro de equipamento |
| Tarefa | `Tarefa` | Item a marcar como feito (limpeza, inspeção, etc.) |
| Finalizar atendimento | `POST …/etapas/{id}/finalizar` | Fecha a **etapa** |
| Finalizar OS | `POST …/servicos/{id}/finalizar` | Fecha o **serviço** inteiro |

IDs importantes:
- `{servico}` → `servicos.id`
- `{etapa}` → `etapas.id`
- `{equipamentoServico}` → `equipamento_servicos.id` (**não** use `equipamentos.id` nas rotas)
- `{tarefa}` → `tarefas.id`

---

## Como chamar a API

**Base:** `{API_BASE_URL}/api`  
Local com Sail: `http://localhost/api`

**Headers em quase tudo:**

```http
Authorization: Bearer {access_token}
X-Platform: mobile
Accept: application/json
Content-Type: application/json
```

`X-Platform: mobile` é **obrigatório no login**. Nos demais endpoints, envie também — deixa explícito que a chamada veio do app.

Uploads (assinatura, foto, anexo) usam `multipart/form-data` em vez de JSON.

**Fuso:** o servidor está em `America/Sao_Paulo`. Datas vêm em ISO-8601.

**Distância até o cliente:** o app calcula no aparelho (GPS vs `cliente.lat` / `cliente.lng`). A API **não** ordena OS por proximidade.

---

## Autenticação

### Login

`POST /api/auth/login` — sem token.

O campo `login` aceita **CPF, e-mail ou telefone**. Prefira só dígitos em CPF/telefone; o servidor ignora pontuação.

```json
{
  "login": "11987654321",
  "password": "senha-secreta"
}
```

**Deu certo (200):** você recebe `access_token`, `expires_in` (segundos) e o objeto `user`.

**Precisa de MFA (200):**

```json
{
  "status": "requires_mfa",
  "mfa_token": "eyJ…"
}
```

Aí chame `POST /api/auth/mfa/verify` com `Authorization: Bearer {mfa_token}` e `{ "code": "123456" }` (ou código de recuperação). A resposta final tem o mesmo formato do login normal.

**Erros comuns de login**

| HTTP | Mensagem | Motivo |
|------|----------|--------|
| 401 | Credenciais inválidas | Login ou senha errados |
| 403 | Sua conta foi desativada | Usuário desativado |
| 403 | …não tem permissão de acesso ao sistema | Falta `LOGIN` |
| 403 | …não tem permissão para acesso mobile | Falta `ACESSO_MOBILE` |
| 422 | Validação Laravel | Campo faltando |

### Depois de logado

| O que | Método | Rota |
|-------|--------|------|
| Renovar token | `POST` | `/api/auth/refresh` |
| Sair | `POST` | `/api/auth/logout` |
| Perfil atual | `GET` | `/api/auth/me` |

"Manter-me conectado" é responsabilidade do app (renovar o token). Todas as rotas `/api/executar/*` precisam do Bearer **e** da permissão `EXECUTAR_SERVICOS`.

---

## Jornada recomendada no app

```
Login
  → Home (dashboard)
  → Lista de OS  ou  Agenda
    → Detalhe da OS
      → Detalhe da etapa
        → Check-in (GPS, até 100 m do cliente)
          → Lista de equipamentos
            → Iniciar equipamento
            → Registrar tag (se for genérico)
            → Checklist (+ fotos)
            → Marcar tarefas
            → Preencher formulário da tarefa (se houver)
            → Finalizar equipamento
          → Enviar assinatura do cliente
          → Finalizar atendimento (fecha a etapa)
    → Finalizar OS (só se todas as etapas estiverem fechadas)
```

Tudo o que muda status (check-in, iniciar, toggle, finalizar, assinatura) **precisa de rede**. Checklist e formulário podem ser rascunhados no aparelho e enviados quando voltar a internet.

---

## 1. Home — dashboard

`GET /api/executar/dashboard`

Números do **dia de hoje** (etapas alocadas ao técnico que cruzam a data atual):

| Campo | Significado |
|-------|-------------|
| `ordens_do_dia` | Quantas OS distintas têm etapa hoje |
| `etapas_feitas` / `etapas_total` | Etapas de hoje já `FINALIZADO` vs total |
| `tempo_medio_minutos` | Média check-in → fim da etapa nos últimos 30 dias. Sem amostras: `null` |
| `proximo_servico` | Próxima etapa `AGUARDANDO` ou `EM_ANDAMENTO`. Pode ser `null` |

`proximo_servico` já traz um resumo da OS e do cliente (incluindo `lat`, `lng` e endereço).

---

## 2. Ordens de serviço

### Listar

`GET /api/executar/servicos`

Filtros opcionais:
- `data_inicio` e `data_fim` (`Y-m-d`) — se mandar um, mande os dois
- `status` — status da **OS**
- `per_page` — 1 a 100; padrão 20

A resposta é paginação Laravel (`data`, `current_page`, `per_page`, `total`).

Cada item traz cliente, tipo de serviço, próxima etapa, e quantas etapas já fecharam (`etapas_closed` / `etapas_total`).

### Detalhe

`GET /api/executar/servicos/{servico}`

- **403** se o técnico não está em nenhuma etapa dessa OS
- **404** se a OS não existe

Dois campos pensados para a UI:
- `etapas_abertas` — etapas ainda não fechadas
- `pode_finalizar_os` — habilite o botão **Finalizar OS** só quando for `true`

### Finalizar OS

`POST /api/executar/servicos/{servico}/finalizar`

Só funciona se **todas** as etapas estiverem `FINALIZADO` ou `CANCELADO`. Não existe "forçar".

Se ainda houver etapa aberta:

```json
{
  "success": false,
  "code": "ETAPAS_ABERTAS",
  "message": "Não é possível finalizar a OS enquanto houver etapas em aberto. Finalize todas as etapas primeiro."
}
```

Mostre a mensagem e peça para fechar as etapas primeiro.

---

## 3. Agenda

Duas rotas, sempre **só as etapas do técnico logado**. Não aparece "aguardando alocação".

### Lista do período

`GET /api/executar/agenda`

| Parâmetro | Obrigatório | Observação |
|-----------|-------------|------------|
| `data_inicio` | sim | `Y-m-d` |
| `data_fim` | sim | `Y-m-d`, intervalo máximo **62 dias** |
| `status` | não | Status de **etapa**, separados por vírgula |

Cada item é uma etapa com resumo da OS e do cliente.

### Ocupação (calendário)

`GET /api/executar/agenda/ocupacao`

Mesmos `data_inicio` / `data_fim` (máx. 62 dias). Devolve, por dia, quantas etapas `AGUARDANDO` ou `EM_ANDAMENTO` começam naquela data.

Útil para pintar o calendário. Intervalo maior que 62 dias → **422**.

> A permissão `VER_AGENDA` existe no cargo, mas o app **não** usa a agenda admin (`/agenda`). Use sempre `/executar/agenda`.

---

## 4. Etapas (o atendimento)

### Listar etapas da OS

`GET /api/executar/servicos/{servico}/etapas`

Só as etapas em que o técnico está alocado.

### Detalhe

`GET /api/executar/etapas/{etapa}`

Traz check-in, assinatura, progresso de equipamentos, colegas da etapa, OS e cliente.

**Status da etapa (o que mostrar na tela)**

| Na tela | Valor gravado |
|---------|---------------|
| Aguardando Check-in | `AGUARDANDO` |
| Em andamento | `EM_ANDAMENTO` |
| Finalizado | `FINALIZADO` |
| Cancelado | `CANCELADO` |

### Check-in

`POST /api/executar/etapas/{etapa}/check-in`

Precisa de **internet + GPS**. O servidor compara com `cliente.lat` / `cliente.lng` e aceita no máximo **100 metros**.

```json
{
  "lat": -22.9068,
  "lng": -43.1729
}
```

Efeitos colaterais:
- etapa vai para `EM_ANDAMENTO`
- se a OS estava `CONFIRMADO` ou `EM_ANALISE`, ela também vai para `EM_ANDAMENTO`
- gera auditoria `ETAPA_CHECKIN`

Fazer check-in de novo numa etapa aberta **é permitido**: atualiza o horário e mantém `EM_ANDAMENTO`.

**Erros**

| Situação | HTTP | O que fazer |
|----------|------|-------------|
| Técnico não alocado | 403 | Não mostrar a ação |
| Cliente sem coordenadas | 422 | Não dá para check-in |
| Mais de 100 m | 422 | Mostrar distância (`data.distancia_metros` / `data.raio_metros`) |
| Etapa já finalizada ou cancelada | 422 | Bloquear |

Exemplo fora da área:

```json
{
  "message": "Você está fora da área permitida para check-in (máximo de 100 metros do cliente).",
  "data": {
    "distancia_metros": 4200,
    "raio_metros": 100
  }
}
```

### Assinatura do cliente

`POST /api/executar/etapas/{etapa}/assinatura`

Multipart. Campo `assinatura`: imagem jpeg/png/jpg/webp, no máximo **5 MB**.

É **obrigatória** antes de finalizar o atendimento. Resposta **201** com `assinatura_url`.

### Finalizar atendimento (fecha a etapa)

`POST /api/executar/etapas/{etapa}/finalizar`

Dois bloqueios importantes:

**1. Sem assinatura** — não passa, sem atalho:

```json
{
  "message": "É necessário capturar a assinatura do cliente antes de finalizar o atendimento.",
  "code": "ASSINATURA_OBRIGATORIA"
}
```

**2. Equipamentos nem começados** — aviso suave. A API devolve `CONFIRMATION_REQUIRED` e conta:
- `equipamentos_nao_iniciados`
- `equipamentos_parciais`
- `equipamentos_concluidos`

Se o técnico confirmar, envie de novo com:

```json
{
  "confirm_remocao_nao_iniciados": true
}
```

Os equipamentos com 0% de tarefas feitas são **desvinculados** da etapa.

---

## 5. Equipamentos da etapa

Prefixo:

`/api/executar/etapas/{etapa}/equipamentos/{equipamentoServico}`

Lembrete: `{equipamentoServico}` é o id da **ligação** (`equipamento_servicos.id`).

### Listar e detalhar

- `GET …/equipamentos` — lista
- `GET …/equipamentos/{equipamentoServico}` — detalhe (checklist + tarefas)

**Badges para a UI**

| Campo | Quando acender |
|-------|----------------|
| `registro_pendente` | Equipamento genérico (`is_generic === true`) — ainda sem tag |
| `checklist_pendente` | Checklist ainda não `PREENCHIDO` |
| `cadastrado` | Já tem tag **e** checklist preenchido |

No detalhe, cada tarefa traz `tem_formulario` e `formulario_status`.

Dá para iniciar e preencher checklist mesmo sem registro; o badge `registro_pendente` só avisa.

### Iniciar

`POST …/equipamentos/{equipamentoServico}/iniciar`

Status vira `EM_ANDAMENTO`. Se já estava iniciado, **não quebra** (idempotente). Se já está `FINALIZADO`, recusa.

### Registrar / editar ficha

`PUT …/equipamentos/{equipamentoServico}/registro`

Transforma genérico em cadastrado (`is_generic = false`) ou atualiza os dados.

Obrigatórios: `tipo_equipamento_id` e `tag`.  
Opcionais: `marca`, `modelo`, `btu`, `evaporadora`, `condensadora`, `localizacao`, `observacoes`.

### Checklist

`PUT …/equipamentos/{equipamentoServico}/checklist`

| Na tela | `status_equipamento` |
|---------|----------------------|
| Normal | `OK` |
| Necessita de Corretiva | `PROBLEMA_IDENTIFICADO` |

`status_equipamento` é obrigatório. Se for `PROBLEMA_IDENTIFICADO`, `problema` também é. O resto (`solucao`, `material`, `tempo_resolucao`, `temperatura`, `observacoes`, fotos) é opcional.

Isso marca `status_checklist = PREENCHIDO`.

### Foto do checklist

`POST …/equipamentos/{equipamentoServico}/checklist/foto`

Multipart: `tipo` = `antes` ou `depois`, mais o arquivo `foto` (imagem, máx. 5 MB).

A resposta traz `path` e `url`. Você pode mandar o `path` no PUT do checklist, ou confiar que o servidor já gravou o campo depois do upload.

### Finalizar equipamento

`POST …/equipamentos/{equipamentoServico}/finalizar`

Se ainda há pendências (tarefa, checklist, formulário), a **primeira chamada avisa** (`CONFIRMATION_REQUIRED`) em vez de recusar de vez.

Mostre o resumo (`tarefas_pendentes`, `checklist_pendente`, etc.) e, se o técnico confirmar, envie:

```json
{
  "confirm_pendencias": true
}
```

---

## 6. Tarefas e formulários

### Marcar tarefa feita / pendente

`PATCH /api/executar/tarefas/{tarefa}/toggle-status`

```json
{ "status": "FEITO" }
```

Valores: `PENDENTE` ou `FEITO`. Se omitir `status`, a API **inverte** o atual.

Marcar **todas** as tarefas como feitas pode finalizar o equipamento automaticamente (cascata no servidor).

### Buscar formulário

`GET /api/executar/tarefas/{tarefa}/formulario`

Devolve o schema (`perguntas`) e rascunho já salvo (`respostas_existentes`).

Se o tipo da tarefa **não tem** formulário → **404**. Trate como "essa tarefa não pede formulário", não como bug de rota.

### Salvar formulário

`POST /api/executar/tarefas/{tarefa}/formulario`

| Campo | Observação |
|-------|------------|
| `formulario_versao_id` | Obrigatório (o mesmo do GET) |
| `status` | `RASCUNHO` ou `ENVIADO` (minúsculas são aceitas e normalizadas) |
| `respostas` | Array; cada item aponta para `formulario_pergunta_id` |

Cada resposta usa o campo que combina com o tipo da pergunta: `value_text`, `value_number`, `value_boolean`, `value_datetime`, `selected_option_id` ou `multiple_options`.

### Anexo de uma resposta

`POST /api/executar/formulario-respostas/{resposta}/anexos`

Campo `file`, até **40 MB**. Resposta **201**. `file_path` já vem com a URL base do storage.

---

## Erros: o que o app deve fazer

### HTTP

| Código | Significado prático |
|--------|---------------------|
| 200 / 201 | Ok |
| 401 | Token ausente ou inválido — refresh ou login de novo |
| 403 | Sem permissão **ou** recurso que não é do técnico |
| 404 | Id inexistente, ou tarefa sem formulário |
| 422 | Regra de negócio ou validação. Olhe `code` e `message` |

Recurso de outro técnico (OS, etapa, equipamento, tarefa) → **403** com mensagem em pt-BR. Não é 404.

Validação Laravel costuma vir assim (às vezes em inglês, às vezes em pt-BR):

```json
{
  "message": "The lat field is required.",
  "errors": {
    "lat": ["The lat field is required."]
  }
}
```

### Códigos de negócio (`code`)

Três códigos que o app precisa tratar de forma especial:

| `code` | Onde | O que o app faz |
|--------|------|-----------------|
| `ASSINATURA_OBRIGATORIA` | Finalizar atendimento | Ir para a tela de assinatura |
| `CONFIRMATION_REQUIRED` | Finalizar equipamento **ou** finalizar atendimento com equipamentos não iniciados | Mostrar aviso e repetir com a flag de confirmação |
| `ETAPAS_ABERTAS` | Finalizar OS | Não tem confirmação — precisa fechar as etapas |

Flags de confirmação:
- equipamento: `confirm_pendencias: true`
- atendimento: `confirm_remocao_nao_iniciados: true`

---

## Status e constantes (referência rápida)

### OS (`servicos.status`)

| Valor | Significado |
|-------|-------------|
| `EM_ANALISE` | Aguardando aprovação |
| `CONFIRMADO` | Aprovada / agendada |
| `EM_ANDAMENTO` | Trabalho em campo começou |
| `FINALIZADO` | OS fechada |
| `RECUSADO` | Recusada |
| `CANCELADO` | Cancelada |

`modalidade`: `AVULSO`, `CONTRATUAL`, `EMERGENCIAL`  
`prioridade`: `BAIXA`, `MEDIA`, `ALTA`

### Etapa
`AGUARDANDO` · `EM_ANDAMENTO` · `FINALIZADO` · `CANCELADO`

### Equipamento da OS
`AGUARDANDO` · `EM_ANDAMENTO` · `FINALIZADO`

### Tarefa
`PENDENTE` · `FEITO`

### Checklist
- Preenchimento: `PENDENTE` / `PREENCHIDO`
- Condição do aparelho: `OK` / `PROBLEMA_IDENTIFICADO`

### Envio de formulário
`RASCUNHO` · `ENVIADO`

### Geofence
Raio máximo de check-in: **100 metros** em relação ao cliente.

---

## Offline vs online

| Ação | Precisa estar online? |
|------|-----------------------|
| Check-in, iniciar equipamento, toggle de tarefa, finalizar equipamento / atendimento / OS, assinatura | **Sim** — não enfileire essas mutações |
| Checklist, formulário, fotos | Pode rascunhar no aparelho; envie com `POST`/`PUT` quando houver rede |

Não existe protocolo de sync. Distância na lista de OS também é só no cliente.

---

## Índice de endpoints

| Método | Rota | Para quê |
|--------|------|----------|
| `POST` | `/api/auth/login` | Entrar |
| `POST` | `/api/auth/mfa/verify` | Confirmar MFA |
| `POST` | `/api/auth/refresh` | Renovar token |
| `POST` | `/api/auth/logout` | Sair |
| `GET` | `/api/auth/me` | Perfil |
| `GET` | `/api/executar/dashboard` | Home |
| `GET` | `/api/executar/servicos` | Lista de OS |
| `GET` | `/api/executar/servicos/{servico}` | Detalhe da OS |
| `GET` | `/api/executar/servicos/{servico}/etapas` | Etapas da OS |
| `POST` | `/api/executar/servicos/{servico}/finalizar` | Finalizar OS |
| `GET` | `/api/executar/agenda` | Agenda |
| `GET` | `/api/executar/agenda/ocupacao` | Contagem por dia |
| `GET` | `/api/executar/etapas/{etapa}` | Detalhe da etapa |
| `POST` | `/api/executar/etapas/{etapa}/check-in` | Check-in |
| `POST` | `/api/executar/etapas/{etapa}/assinatura` | Assinatura |
| `POST` | `/api/executar/etapas/{etapa}/finalizar` | Finalizar atendimento |
| `GET` | `/api/executar/etapas/{etapa}/equipamentos` | Lista de equipamentos |
| `GET` | `/api/executar/etapas/{etapa}/equipamentos/{equipamentoServico}` | Detalhe do equipamento |
| `POST` | `…/equipamentos/{equipamentoServico}/iniciar` | Iniciar |
| `PUT` | `…/equipamentos/{equipamentoServico}/registro` | Tag / ficha |
| `PUT` | `…/equipamentos/{equipamentoServico}/checklist` | Checklist |
| `POST` | `…/equipamentos/{equipamentoServico}/checklist/foto` | Foto antes/depois |
| `POST` | `…/equipamentos/{equipamentoServico}/finalizar` | Finalizar equipamento |
| `PATCH` | `/api/executar/tarefas/{tarefa}/toggle-status` | Marcar tarefa |
| `GET` | `/api/executar/tarefas/{tarefa}/formulario` | Schema do formulário |
| `POST` | `/api/executar/tarefas/{tarefa}/formulario` | Salvar formulário |
| `POST` | `/api/executar/formulario-respostas/{resposta}/anexos` | Anexo da resposta |
