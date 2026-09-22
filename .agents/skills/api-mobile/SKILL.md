---
name: api-mobile
description: >
  Documentação completa da API REST para o app mobile do técnico de campo
  (Grupo LoboRJ / arcondicionado). Contém todos os endpoints prontos,
  payloads, status, regras de negócio e guia de integração Flutter.
  Ativar sempre que for implementar ou modificar qualquer camada de rede,
  repositório, datasource ou feature que consuma a API backend.
---

# API Mobile — Guia do Técnico de Campo

> Documento: `GUIA_API_MOBILE.md` (copiado de https://www.mdshare.online/s/xjDlOBvZISh3TZ8uPMrii)
> A URL base da API vem da variável de ambiente `API_BASE_URL` definida em `.env`.

---

## Para quem é o app

Público: **técnico de campo** com cargo `TÉCNICO` e permissões:

- `LOGIN` — entra no sistema
- `ACESSO_MOBILE` — entra pelo app (header `X-Platform: mobile`)
- `EXECUTAR_SERVICOS` — usa tudo que começa com `/api/executar/`

O técnico **só vê o que foi alocado para ele**. Fora do escopo: painel de admin, pagamento, contratos.

---

## Como chamar a API

**Base:** `{API_BASE_URL}/api`  
Local com Sail: `http://localhost/api`

**Headers obrigatórios em quase tudo:**

```http
Authorization: Bearer {access_token}
X-Platform: mobile
Accept: application/json
Content-Type: application/json
```

- `X-Platform: mobile` é **obrigatório no login**. Envie em todos os endpoints.
- Uploads (assinatura, foto, anexo) usam `multipart/form-data`.
- **Fuso:** servidor em `America/Sao_Paulo`. Datas em ISO-8601.
- **Distância ao cliente:** calculada no app via GPS vs `cliente.lat`/`cliente.lng`. A API **não** ordena por proximidade.

---

## Jornada no app

```
Login
  → Home (dashboard)
  → Lista de OS  ou  Agenda
    → Detalhe da OS
      → Detalhe da etapa
        → Check-in (GPS, ≤ 100 m do cliente)
          → Lista de equipamentos
            → Iniciar equipamento
            → Registrar tag (se genérico)
            → Checklist (+ fotos)
            → Marcar tarefas
            → Preencher formulário da tarefa (se houver)
            → Finalizar equipamento
          → Enviar assinatura do cliente
          → Finalizar atendimento (fecha a etapa)
    → Finalizar OS (só se todas as etapas fechadas)
```

**Online obrigatório:** check-in, iniciar, toggle, finalizar, assinatura.  
**Pode ser offline (rascunho):** checklist, formulário, fotos.

---

## Autenticação

### Login
`POST /api/auth/login` — sem token.

```json
{
  "login": "11987654321",
  "password": "senha-secreta"
}
```

O campo `login` aceita **CPF, e-mail ou telefone** (só dígitos para CPF/telefone).

**200 OK (sucesso):** retorna `access_token`, `expires_in` (segundos), objeto `user`.

**200 (MFA necessário):**
```json
{
  "status": "requires_mfa",
  "mfa_token": "eyJ…"
}
```
Chame `POST /api/auth/mfa/verify` com `Authorization: Bearer {mfa_token}` e `{ "code": "123456" }`.

**Erros de login:**

| HTTP | Mensagem | Motivo |
|------|----------|--------|
| 401 | Credenciais inválidas | Login ou senha errados |
| 403 | Sua conta foi desativada | Usuário desativado |
| 403 | …não tem permissão de acesso ao sistema | Falta `LOGIN` |
| 403 | …não tem permissão para acesso mobile | Falta `ACESSO_MOBILE` |
| 422 | Validação Laravel | Campo faltando |

### Após login

| O que | Método | Rota |
|-------|--------|------|
| Renovar token | `POST` | `/api/auth/refresh` |
| Sair | `POST` | `/api/auth/logout` |
| Perfil atual | `GET` | `/api/auth/me` |

"Manter-me conectado" é responsabilidade do app (renovar token). Todas as rotas `/api/executar/*` precisam do Bearer **e** da permissão `EXECUTAR_SERVICOS`.

---

## 1. Home — Dashboard

`GET /api/executar/dashboard`

Números do **dia de hoje** (etapas alocadas ao técnico que cruzam a data atual):

| Campo | Significado |
|-------|-------------|
| `ordens_do_dia` | Quantas OS distintas têm etapa hoje |
| `etapas_feitas` / `etapas_total` | Etapas de hoje já `FINALIZADO` vs total |
| `tempo_medio_minutos` | Média check-in → fim da etapa (30 dias). Sem amostras: `null` |
| `proximo_servico` | Próxima etapa `AGUARDANDO` ou `EM_ANDAMENTO`. Pode ser `null` |

`proximo_servico` já traz resumo da OS e do cliente (incluindo `lat`, `lng` e endereço).

---

## 2. Ordens de Serviço

### Listar
`GET /api/executar/servicos`

Filtros opcionais:
- `data_inicio` e `data_fim` (`Y-m-d`) — se mandar um, mande os dois
- `status` — status da OS
- `per_page` — 1 a 100; padrão 20

Resposta: paginação Laravel (`data`, `current_page`, `per_page`, `total`).
Cada item traz: cliente, tipo de serviço, próxima etapa, `etapas_closed`/`etapas_total`.

### Detalhe
`GET /api/executar/servicos/{servico}`

- **403** se o técnico não está em nenhuma etapa dessa OS
- **404** se a OS não existe

Campos para UI:
- `etapas_abertas` — etapas ainda não fechadas
- `pode_finalizar_os` — habilite o botão **Finalizar OS** só quando `true`

### Finalizar OS
`POST /api/executar/servicos/{servico}/finalizar`

Só funciona se **todas** as etapas estiverem `FINALIZADO` ou `CANCELADO`. Se ainda houver etapa aberta:

```json
{
  "success": false,
  "code": "ETAPAS_ABERTAS",
  "message": "Não é possível finalizar a OS enquanto houver etapas em aberto. Finalize todas as etapas primeiro."
}
```

---

## 3. Agenda

### Lista do período
`GET /api/executar/agenda`

| Parâmetro | Obrigatório | Observação |
|-----------|-------------|------------|
| `data_inicio` | sim | `Y-m-d` |
| `data_fim` | sim | `Y-m-d`, intervalo máximo **62 dias** |
| `status` | não | Status de **etapa**, separados por vírgula |

### Ocupação (calendário)
`GET /api/executar/agenda/ocupacao`

Mesmos `data_inicio`/`data_fim` (máx. 62 dias). Retorna por dia quantas etapas `AGUARDANDO` ou `EM_ANDAMENTO` começam naquela data. Útil para pintar o calendário.
Intervalo > 62 dias → **422**.

> Use sempre `/executar/agenda`, não `/agenda` (admin).

---

## 4. Etapas (o atendimento)

### Listar etapas da OS
`GET /api/executar/servicos/{servico}/etapas`

Só as etapas em que o técnico está alocado.

### Detalhe
`GET /api/executar/etapas/{etapa}`

Traz check-in, assinatura, progresso de equipamentos, colegas da etapa, OS e cliente.

**Status da etapa:**

| Na tela | Valor gravado |
|---------|---------------|
| Aguardando Check-in | `AGUARDANDO` |
| Em andamento | `EM_ANDAMENTO` |
| Finalizado | `FINALIZADO` |
| Cancelado | `CANCELADO` |

### Check-in
`POST /api/executar/etapas/{etapa}/check-in`

Precisa de **internet + GPS**. O servidor aceita no máximo **100 metros** do cliente.

```json
{
  "lat": -22.9068,
  "lng": -43.1729
}
```

Efeitos colaterais:
- Etapa vai para `EM_ANDAMENTO`
- Se OS estava `CONFIRMADO` ou `EM_ANALISE`, também vai para `EM_ANDAMENTO`
- Gera auditoria `ETAPA_CHECKIN`

Re-check-in em etapa aberta é **permitido** (idempotente, atualiza horário).

**Erros:**

| Situação | HTTP | O que fazer |
|----------|------|-------------|
| Técnico não alocado | 403 | Não mostrar a ação |
| Cliente sem coordenadas | 422 | Não dá para check-in |
| Mais de 100 m | 422 | Mostrar `data.distancia_metros` / `data.raio_metros` |
| Etapa já finalizada/cancelada | 422 | Bloquear |

### Assinatura do cliente
`POST /api/executar/etapas/{etapa}/assinatura`

Multipart. Campo `assinatura`: imagem jpeg/png/jpg/webp, máx. **5 MB**.
**Obrigatória** antes de finalizar. Resposta **201** com `assinatura_url`.

### Finalizar atendimento (fecha a etapa)
`POST /api/executar/etapas/{etapa}/finalizar`

**Bloqueio 1 — Sem assinatura** (sem atalho):
```json
{
  "message": "É necessário capturar a assinatura do cliente antes de finalizar o atendimento.",
  "code": "ASSINATURA_OBRIGATORIA"
}
```

**Bloqueio 2 — Equipamentos não iniciados** (`CONFIRMATION_REQUIRED`):
Retorna `equipamentos_nao_iniciados`, `equipamentos_parciais`, `equipamentos_concluidos`.
Se técnico confirmar, envie novamente com:
```json
{ "confirm_remocao_nao_iniciados": true }
```

---

## 5. Equipamentos da Etapa

Prefixo: `/api/executar/etapas/{etapa}/equipamentos/{equipamentoServico}`

> `{equipamentoServico}` = `equipamento_servicos.id` (não use `equipamentos.id`)

### Listar e detalhar
- `GET …/equipamentos` — lista
- `GET …/equipamentos/{equipamentoServico}` — detalhe (checklist + tarefas)

**Badges para UI:**

| Campo | Quando acender |
|-------|----------------|
| `registro_pendente` | Equipamento genérico (`is_generic === true`) — sem tag |
| `checklist_pendente` | Checklist ainda não `PREENCHIDO` |
| `cadastrado` | Já tem tag **e** checklist preenchido |

No detalhe, cada tarefa traz `tem_formulario` e `formulario_status`.

### Iniciar
`POST …/equipamentos/{equipamentoServico}/iniciar`

Status vira `EM_ANDAMENTO`. Se já iniciado: **idempotente**. Se `FINALIZADO`: recusa.

### Registrar / editar ficha
`PUT …/equipamentos/{equipamentoServico}/registro`

Transforma genérico em cadastrado (`is_generic = false`) ou atualiza dados.

Obrigatórios: `tipo_equipamento_id`, `tag`.
Opcionais: `marca`, `modelo`, `btu`, `evaporadora`, `condensadora`, `localizacao`, `observacoes`.

### Checklist
`PUT …/equipamentos/{equipamentoServico}/checklist`

| Na tela | `status_equipamento` |
|---------|----------------------|
| Normal | `OK` |
| Necessita de Corretiva | `PROBLEMA_IDENTIFICADO` |

`status_equipamento` é obrigatório. Se `PROBLEMA_IDENTIFICADO`, `problema` também é.
Opcionais: `solucao`, `material`, `tempo_resolucao`, `temperatura`, `observacoes`, fotos.
Marca `status_checklist = PREENCHIDO`.

### Foto do checklist
`POST …/equipamentos/{equipamentoServico}/checklist/foto`

Multipart: `tipo` = `antes` ou `depois`, arquivo `foto` (imagem, máx. 5 MB).
Resposta traz `path` e `url`.

### Finalizar equipamento
`POST …/equipamentos/{equipamentoServico}/finalizar`

Se há pendências: primeira chamada retorna `CONFIRMATION_REQUIRED` com `tarefas_pendentes`, `checklist_pendente`, etc.
Se técnico confirmar:
```json
{ "confirm_pendencias": true }
```

---

## 6. Tarefas e Formulários

### Marcar tarefa feita / pendente
`PATCH /api/executar/tarefas/{tarefa}/toggle-status`

```json
{ "status": "FEITO" }
```

Valores: `PENDENTE` ou `FEITO`. Se omitir `status`, a API **inverte** o atual.
Marcar **todas** as tarefas como `FEITO` pode finalizar o equipamento automaticamente (cascata).

### Buscar formulário
`GET /api/executar/tarefas/{tarefa}/formulario`

Retorna `perguntas` (schema) e `respostas_existentes` (rascunho).
Se tipo não tem formulário → **404** (trate como "sem formulário", não bug).

### Salvar formulário
`POST /api/executar/tarefas/{tarefa}/formulario`

| Campo | Observação |
|-------|------------|
| `formulario_versao_id` | Obrigatório (mesmo do GET) |
| `status` | `RASCUNHO` ou `ENVIADO` (minúsculas aceitas) |
| `respostas` | Array; cada item aponta para `formulario_pergunta_id` |

Tipos de resposta: `value_text`, `value_number`, `value_boolean`, `value_datetime`, `selected_option_id`, `multiple_options`.

### Anexo de uma resposta
`POST /api/executar/formulario-respostas/{resposta}/anexos`

Campo `file`, até **40 MB**. Resposta **201**. `file_path` vem com URL base do storage.

---

## Erros — O que o app deve fazer

### HTTP

| Código | Significado prático |
|--------|---------------------|
| 200 / 201 | Ok |
| 401 | Token ausente ou inválido — refresh ou login de novo |
| 403 | Sem permissão **ou** recurso que não é do técnico |
| 404 | Id inexistente, ou tarefa sem formulário |
| 422 | Regra de negócio ou validação — olhe `code` e `message` |

Recurso de outro técnico → **403** (não 404).

### Códigos de negócio (`code`)

| `code` | Onde | O que o app faz |
|--------|------|-----------------|
| `ASSINATURA_OBRIGATORIA` | Finalizar atendimento | Ir para tela de assinatura |
| `CONFIRMATION_REQUIRED` | Finalizar equipamento ou finalizar atendimento com equipamentos não iniciados | Mostrar aviso e repetir com flag de confirmação |
| `ETAPAS_ABERTAS` | Finalizar OS | Sem confirmação — precisa fechar as etapas |

**Flags de confirmação:**
- Equipamento: `confirm_pendencias: true`
- Atendimento: `confirm_remocao_nao_iniciados: true`

---

## Status e Constantes — Referência Rápida

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

### Formulário
`RASCUNHO` · `ENVIADO`

### Geofence
Raio máximo de check-in: **100 metros** em relação ao cliente.

---

## Offline vs Online

| Ação | Precisa estar online? |
|------|-----------------------|
| Check-in, iniciar equipamento, toggle de tarefa, finalizar equipamento/atendimento/OS, assinatura | **Sim** — não enfileire essas mutações |
| Checklist, formulário, fotos | Pode rascunhar; envie com POST/PUT quando houver rede |

---

## Índice de Endpoints

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

---

## Padrões Flutter do Projeto

- **HTTP client:** `Dio` via `ApiClient` (em `lib/core/network/api_client.dart`)
- **Base URL:** lida de `.env` via `API_BASE_URL` → injetada em `ApiConstants.baseUrl`
- **Token storage:** `SecureStorageService` (flutter_secure_storage)
- **Refresh automático:** já implementado no interceptor do `ApiClient` (401 → POST /auth/refresh)
- **State management:** `flutter_bloc`
- **DI:** `get_it`
- **Arquitetura:** Feature-first (lib/features/{feature}/data/repositories|datasources, domain/entities|repositories|usecases, presentation/bloc|pages|widgets)
- **Constantes de rota:** adicionar em `lib/core/constants/api_constants.dart`
