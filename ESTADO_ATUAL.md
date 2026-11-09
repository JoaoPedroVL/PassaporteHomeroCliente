# Passaporte Brasil — Estado Atual do Projeto

**Data:** 09/11/2026

**Projeto Supabase:** `kxjggwwupnskjeqquefu`

**Aplicativos:** `HomeroPassaporteCLIENTE` (viajante) e `HomeroPassaporteADM` (administração)

---

## 1. Resumo

O app do viajante está **funcional e sem erros de análise**. Os dois bloqueios
que existiam em novembro foram resolvidos:

| Item | Estado |
|---|---|
| Publicar no Padlet | ✅ corrigido e testado no banco |
| Padlet somente leitura após o fim da viagem | ✅ banco + interface |
| Realtime do Padlet filtrado por viagem | ✅ |
| Campo de data de nascimento com máscara | ✅ |
| `flutter analyze` (cliente e ADM) | ✅ sem problemas |
| Testes automatizados do cliente | ✅ 36 passando |
| Concessão de insígnias | ❌ não implementado |

---

## 2. Stack e estrutura

| Item | Valor |
|---|---|
| Flutter | 3.47.0 (stable) |
| Dart SDK | compatível com Flutter 3.47 |
| `supabase_flutter` | ^2.5.0 (resolvido em 2.18.0) |
| Outras dependências (cliente) | `flutter_dotenv`, `image_picker`, `cupertino_icons` |
| Outras dependências (ADM) | `csv`, `file_picker`, `pdf`, `file_saver` |
| App ID Android | `br.com.passaportebrasil.cliente` |
| Nome exibido | Passaporte Brasil |
| Versão | `0.1.0+1` |

### Tamanho do código

| Projeto | Arquivos `.dart` | Linhas |
|---|---|---|
| Cliente | 47 | 9.176 |
| ADM | 25 | 15.765 |

Não há `TODO`, `FIXME` ou `HACK` pendentes no código do cliente.

### Versionamento

| Projeto | Branch | Último commit | Arquivos não commitados |
|---|---|---|---|
| Cliente | `main` | 26/10/2026 | 25 |
| ADM | `main` | 26/10/2026 | 43 |

Os dois têm remote no GitHub (`JoaoPedroVL/PassaporteHomeroCliente` e
`JoaoPedroVL/PassaporteHomero`). **Todo o trabalho de novembro ainda está
não commitado.**

---

## 3. Funcionalidades prontas — Cliente

### Autenticação e conta

- Login por **CPF ou e-mail**; o CPF é convertido para
  `<cpf>@cpf.passaportebrasil.local` internamente.
- Máscara de CPF e validação de dígitos.
- Ativação de conta importada por **código individual**.
- Troca de senha forçada quando `must_change_password = true`.
- Tela de conta inativa com opção de sair e nova tentativa.
- `touch_last_seen()` registra o último acesso.

### LGPD

- Aviso de privacidade com versão (`privacy_version`).
- Consentimento do responsável para menores.
- Consentimento de imagem antes de publicar fotos.
- **Data de nascimento digitável**: aceita `18122001` e mostra `18/12/2001`,
  com backspace nas barras, atalho de calendário e validações:
  - recusa datas inexistentes (`31/02`, `18/13`);
  - recusa futuro e ano anterior a 1900;
  - idade máxima de 120 anos.

### Navegação

Abas: **Início, Passaporte, Insígnias, Padlet e Perfil**.

- **Início**: viagens `published` com término a partir de hoje.
- **Passaporte**: viagens do viajante em “Em andamento”, “Próximos carimbos”
  e “Já vividas”.
- **Insígnias**: coleção conquistada e bloqueada, com progresso.
- **Padlet**: visão geral com seletor de viagem.
- **Perfil**: dados, CPF, consentimentos e saída.

### Detalhe da viagem

Roteiro, Padlet da viagem, dia a dia com anotações pessoais, checklist,
contatos de emergência e avaliação.

### Padlet

- **Um mural por viagem** (não existe entidade “board” separada; o vínculo é
  `wall_posts.trip_id`).
- Texto + até **4 fotos** por publicação.
- Fotos no bucket privado `wall-photos`, exibidas por URL assinada.
- MIME normalizado para `image/jpeg`, `image/png` ou `image/webp`.
- Publicações do viajante entram como `pending` e só aparecem ao grupo
  depois da moderação (`approved`). O autor sempre vê o próprio post.
- **Realtime filtrado por `trip_id`** no servidor, com debounce de 350 ms.
- Ao trocar de viagem, o canal é recriado com o novo filtro.
- **Somente leitura depois do fim da viagem**: sem novos posts e sem novas
  fotos; o que já foi publicado continua visível.

---

## 4. Banco de dados

### Objetos

23 tabelas/views em `public`, todas do domínio Passaporte:

`users`, `groups`, `organizations`, `cohorts`, `trips`, `trip_groups`,
`trip_participants`, `route_steps`, `trip_days`, `checklist_items`,
`checklist_progress`, `emergency_contacts`, `annotations`, `wall_posts`,
`wall_post_images`, `reviews`, `badges`, `user_badges`, `notifications`,
`user_activation_codes`, `user_imports`, `user_consents` e a view
`public_profiles`.

> Observação: o banco do **SaaS de lava-jato** (`tenants`, `bookings`,
> `services`, `vehicles`, etc.) é um **projeto separado** e não existe aqui.

### Conteúdo atual

| Tabela | Linhas |
|---|---|
| `users` | 3 |
| `trips` | 5 (3 publicadas, 2 rascunhos) |
| `trip_participants` | 6 |
| `wall_posts` | 3 (todos aprovados, do seed) |
| `wall_post_images` | 0 |
| `badges` | 4 |
| `user_badges` | 2 |
| `organizations` | 1 |
| `cohorts` | 0 |
| `annotations` | 3 |
| `reviews` | 3 |
| `notifications` | 0 |
| `user_consents` | 3 |

### Viagens

| Viagem | Status | Período |
|---|---|---|
| Clássico em São Paulo | `draft` | 22/10 → 24/10 |
| minas | `published` | 26/10 → 29/10 |
| Inglaterra e seus dizeres | `draft` | 28/10 → 01/11 |
| Marrocos | `published` | 29/10 → 31/10 |
| Miame | `published` | 31/10 → 02/11 |

**Todas as viagens publicadas já terminaram.** Por isso a aba Início está
vazia hoje (`end_date >= hoje`). Não é bug — é consequência dos dados.

### Insígnias

| Insígnia | Tipo | Ativa |
|---|---|---|
| Primeira Jornada | manual | sim |
| Explorador | manual | sim |
| Contador de Histórias | manual | sim |
| Embaixador do Passaporte | manual | sim |

Nenhum caminho de concessão existe hoje: não há botão no ADM nem trigger
automático. As 2 concessões em `user_badges` são do seed da conta demo.

### Usuários

| Nome | Status | CPF | Organização |
|---|---|---|---|
| Admin Demo | active | — | não |
| Bruno | active | 175.019.017-67 | sim |
| Viajante Demo | active | 123.456.789-09 | sim |

Todos com `must_change_password = false`.

### Auth

4 usuários no Supabase Auth, sendo **1 órfão sem perfil** em `public.users`:

```
joao@teste.com  ·  criado em 21/09/2026
```

Se logar, o app cai na tela de “perfil ausente”. Pode ser removido.

---

## 5. RLS e funções

### Funções de permissão

`is_active_user()`, `is_admin()`, `is_global_admin()`, `is_org_admin()`,
`can_manage_org()`, `can_manage_trip()`, `can_access_trip()`,
`can_view_wall_post()`, `can_edit_wall_post()`, `can_manage_wall_post()`,
`can_manage_badge()` e, novas em novembro:

- **`can_post_in_trip(trip_id)`** — pode publicar nesta viagem?
- **`can_add_wall_image(post_id)`** — pode anexar foto neste post?

### Policies do Padlet (estado atual)

| Tabela | Operação | Regra |
|---|---|---|
| `wall_posts` | SELECT | admin da viagem, autor, ou aprovado em viagem acessível |
| `wall_posts` | INSERT | ativo + autor + `pending` + `can_post_in_trip` |
| `wall_posts` | UPDATE | autor (pendente, dentro da janela) ou admin |
| `wall_posts` | DELETE | autor ou admin |
| `wall_post_images` | INSERT | `can_add_wall_image(post_id)` |
| `wall_post_images` | SELECT | `can_view_wall_post(post_id)` |
| `wall_post_images` | UPDATE/DELETE | admin / autor |

### Janela de publicação

A regra usa o fuso **`America/Sao_Paulo`**:

```sql
(now() at time zone 'America/Sao_Paulo')::date <= trips.end_date
```

Sem isso, às 21h do último dia o banco (UTC) já bloquearia a publicação.
Administradores da viagem continuam podendo moderar depois do encerramento.

---

## 6. Migrations

15 arquivos em `HomeroPassaporteADM/supabase/migrations/`, **todos já
refletidos no banco**:

| # | Arquivo |
|---|---|
| 1 | `20261005150837_groups_rls_policies.sql` |
| 2 | `20261023010500_badges_rls_policies.sql` |
| 3 | `20261023090000_critical_rls_fixes.sql` |
| 4 | `20261023160000_client_history_and_inactive_users.sql` |
| 5 | `20261023161000_enable_realtime_client_tables.sql` |
| 6 | `20261023170000_client_ui_support.sql` |
| 7 | `20261026090000_cpf_groups_trip_badges_wall_images.sql` |
| 8 | `20261027120000_lgpd_p0_security_and_consent.sql` |
| 9 | `20261028120000_organizations_cohorts_import_activation.sql` |
| 10 | `20261028200000_institution_admin_rls.sql` |
| 11 | `20261028210000_pagination_search_indexes.sql` |
| 12 | `20261028220000_async_import_jobs.sql` |
| 13 | `20261028230000_trip_people_scale.sql` |
| 14 | `20261029120000_fix_wall_posts_insert_policy.sql` |
| 15 | `20261104120000_lock_padlet_after_trip_end.sql` |

> **Não existe a tabela `supabase_migrations.schema_migrations`.** O banco foi
> montado fora do controle do CLI, então `supabase db push` tentaria aplicar
> tudo de novo. Para usar o CLI no futuro, é preciso marcar as 15 como
> aplicadas (`supabase migration repair --status applied <versão>`).

---

## 7. Correções de novembro/2026

### 7.1 Publicação no Padlet retornava 42501

**Sintoma:** “Você não tem acesso a este conteúdo” ao publicar.

**Causa:** o cliente faz `.insert(...).select('id')`, que gera
`INSERT ... RETURNING id`. O PostgreSQL aplica a policy de **SELECT** nas
linhas devolvidas. A policy chamava `can_view_wall_post(id)`, uma função
`STABLE` que consulta a própria `wall_posts` — e funções `STABLE` usam o
snapshot da instrução, que **não contém a linha recém-inserida**. Resultado:
o banco recusava o insert.

**Correção:** policy de SELECT reescrita inline, sem consultar `wall_posts`
por dentro de função `STABLE`.

**Provas:**

| Teste | Resultado |
|---|---|
| `INSERT` sem `RETURNING` | ✅ passa |
| `INSERT ... RETURNING id` | ❌ 42501 (antes) |
| `INSERT` + `SELECT` posterior | ✅ passa |

### 7.2 Padlet somente leitura após o fim

Implementado em duas camadas:

- **Banco:** `can_post_in_trip` e `can_add_wall_image`, aplicadas nas policies
  de INSERT/UPDATE de posts e imagens.
- **Interface:** o composer vira um card “Viagem encerrada / Somente leitura”;
  o botão “Criar Padlet” some; as ações de publicar e anexar foto têm guarda.

**Testes executados:**

| Cenário | Resultado |
|---|---|
| Viagem ativa — post | ✅ 201 |
| Viagem ativa — foto | ✅ 201 |
| Viagem terminando hoje — post | ✅ 201 |
| Viagem terminada ontem — post | ❌ 403 |
| Viagem terminada ontem — foto | ❌ 403 |

### 7.3 Outras correções

- Realtime do Padlet filtrado por `trip_id` + debounce de 350 ms.
- Campo de data de nascimento com máscara e validações.
- Limpeza de dados de teste: viagens `fr`, `das`, `ba`, post `gbhj`,
  11 insígnias de teste e arquivo órfão no storage.

---

## 8. Builds

| Artefato | Data | Tamanho | Situação |
|---|---|---|---|
| `app-release.apk` | 04/11 12:01 | 58,0 MB | ✅ atual (md5 `5c92c8dcaf2a50214b5f9e22fbdaa9c2`) |
| `app-debug.apk` | 29/10 15:41 | 158 MB | ❌ desatualizado |
| `build/web` | 28/10 | — | ❌ desatualizado |

O APK release inclui todas as mudanças de novembro. Não há servidor de
download ativo no momento; o último usado foi
`http://10.101.2.139:8000/passaporte-brasil.apk`.

### Ambiente Android

Configuração permanente já aplicada:

- `flutter config --jdk-dir=/home/joao/.jdks/jdk-21.0.13+9`
- `android/local.properties` → `sdk.dir=/home/joao/Android/Sdk`
- `android/gradle.properties` → `org.gradle.java.home` e
  `org.gradle.java.installations.paths`
- `build.gradle.kts` com imports explícitos; `ndkVersion` removido.

---

## 9. Pendências e próximos passos

### Prioridade alta

| # | Item | Observação |
|---|---|---|
| 1 | **Commit e push do trabalho de novembro** | 25 arquivos no cliente e 43 no ADM sem commit |
| 2 | **Concessão de insígnias** | Maior lacuna funcional: nenhum caminho automático ou manual no ADM |
| 3 | Remover usuário órfão `joao@teste.com` | Evita tela de “perfil ausente” |
| 4 | Criar histórico de migrations | Para `supabase db push` funcionar |

### Prioridade média

| # | Item | Observação |
|---|---|---|
| 5 | Início vazio com viagens encerradas | Decidir se mostra viagens recentes ou mensagem melhor |
| 6 | Testar `must_change_password = true` | Nunca foi exercitado de ponta a ponta |
| 7 | Semântica de exclusão de inativos (>10 meses) | Regra ainda não confirmada |
| 8 | Distribuição do APK | Google Drive via `rclone` ou servidor local |

### Performance e robustez

| # | Item | Impacto |
|---|---|---|
| 9 | `Future.wait` no detalhe da viagem | 6 consultas em série → 3–5 s no 4G ruim |
| 10 | Paginação do Padlet | Limite fixo de 60 posts; o 61º nunca aparece |
| 11 | Fila offline | Post que falha perde texto e fotos |
| 12 | Crash reporting | Erros só em `debugPrint` |
| 13 | Realtime de `wall_post_images` | Não tem `trip_id`; filtro é feito no cliente |

---

## 10. Riscos conhecidos

- **Sem crash reporting**: falhas em produção não são visíveis.
- **Sem fila offline**: perda de conteúdo em conexão instável.
- **Limite de 60 posts** no mural, sem paginação.
- **Fuso**: a interface usa a data do celular; o banco usa
  `America/Sao_Paulo`. Pode haver diferença de horas no último dia.
- **Sem histórico de migrations**: o banco e o repositório podem divergir
  silenciosamente.

---

## 11. Arquivos-chave

### Cliente

| Arquivo | Responsabilidade |
|---|---|
| `lib/widgets/trip_padlet.dart` | Padlet por viagem, composer, realtime, somente leitura |
| `lib/data/consultas.dart` | Consultas, `criarPost`, URLs assinadas |
| `lib/core/data_br.dart` | Máscara e validação de data |
| `lib/widgets/campo_data.dart` | Campo de data com calendário |
| `lib/core/error_messages.dart` | Tradução de erros (42501, storage) |
| `lib/pages/trip_detail_page.dart` | Detalhe da viagem |
| `test/widget_test.dart` | 36 testes |

### ADM

| Arquivo | Responsabilidade |
|---|---|
| `supabase/migrations/20261029120000_fix_wall_posts_insert_policy.sql` | Correção do RETURNING |
| `supabase/migrations/20261104120000_lock_padlet_after_trip_end.sql` | Somente leitura após o fim |

### Build

```
HomeroPassaporteCLIENTE/build/app/outputs/flutter-apk/app-release.apk
```

---

## 12. Como rodar

```bash
cd ~/Documentos/codigos/HomeroPassaporteCLIENTE
flutter pub get
flutter run                 # dispositivo conectado
flutter test                # 36 testes
flutter analyze

# APK release
flutter build apk --release
```

Para publicar no Google Drive, é preciso configurar `rclone` uma vez; não há
credencial configurada nesta máquina.

---

*Documento gerado em 09/11/2026 a partir do código, dos testes e do banco de
produção.*
