# Passaporte Brasil — App do Viajante

Aplicativo Flutter para os viajantes acompanharem as viagens publicadas pelo
administrador do seu grupo. Autenticação e dados são servidos pelo Supabase
(mesmo projeto do painel `HomeroPassaporteADM`).

## Como rodar

```bash
flutter pub get
cp .env.example .env   # preencha SUPABASE_URL e SUPABASE_ANON_KEY
flutter run
```

O arquivo `.env` é um asset do app e está no `.gitignore`. Em builds/CI, crie-o
a partir do `.env.example` antes de compilar.

Para testar no navegador:

```bash
flutter build web --release
python3 -m http.server 8080 --directory build/web
# abra http://localhost:8080
```

Se a porta 8080 estiver ocupada pelo painel do ADM, use outra porta
(`python3 -m http.server 8081 --directory build/web`).

## Estrutura

```
lib/
├── core/       cliente Supabase, formatadores e mensagens de erro
├── data/       consultas ao banco (viagens, passaporte, mural, etc.)
├── models/     modelos de dados
├── pages/      login, AccountGate, AppShell e as cinco áreas do app
├── theme/      identidade visual "Passaporte premium"
├── widgets/    componentes reutilizáveis (capa, carimbo, cartões, estados)
└── main.dart   bootstrap, validação de configuração e AuthGate
assets/fonts/   Crimson Text (títulos serifados)
docs/screenshots/ capturas das telas
```

## Comportamento

- Sem sessão → tela de login.
- Login por **CPF ou e-mail**. Contas importadas pela instituição recebem um
  **código de ativação individual**; o aluno usa "Ativar meu cadastro com
  código", informa CPF + código e cria a própria senha. O cliente converte o
  CPF no e-mail interno do Supabase Auth
  (`<cpf>@cpf.passaportebrasil.local`) sem exibir isso ao viajante.
- No primeiro acesso após a ativação, o aluno aceita o Aviso de Privacidade e,
  se menor, informa o responsável legal. O consentimento de imagem é pedido
  antes de publicar fotos no mural.
- No primeiro acesso, `must_change_password = true` abre a tela de criação de
  senha. A troca usa `auth.updateUser` + RPC `mark_password_changed()`.
- Com sessão → `AccountGate` consulta o perfil em `users`:
  - `status = 'active'` → `AppShell` com Início, Passaporte, Insígnias, Padlet e
    Perfil;
  - qualquer outro status → tela de conta inativa (o usuário pode sair ou
    aguardar a reativação, que chega por Realtime);
  - perfil ausente ou falha de rede → tela de aviso com nova tentativa.
- Início mostra as viagens `published` com término a partir de hoje.
- Passaporte mostra as viagens em que o viajante é participante, separadas em
  Em andamento, Próximos carimbos e Já vividas.
- Insígnias mostra a coleção (conquistadas e bloqueadas) e o progresso.
- **Padlet por viagem**: cada viagem tem seu próprio mural. A aba global
  "Padlet" funciona como visão geral e permite alternar entre as viagens; dentro
  do detalhe de cada viagem, a aba "Padlet" abre o mural daquela viagem, com
  composer de texto + até 4 fotos e feed filtrado. Ao publicar a primeira
  memória, o Padlet daquela viagem passa a existir. As fotos vão para o bucket
  privado `wall-photos` e são exibidas por URL assinada. O MIME type é
  normalizado para `image/jpeg`, `image/png` ou `image/webp`, os formatos
  aceitos pelo bucket (o seletor do Linux devolve `mimeType` nulo).
- Posts passam por moderação (`pending` → `approved`) antes de aparecer para o
  grupo. O autor sempre vê o próprio post, mesmo pendente.
- **Depois do último dia da viagem o Padlet fica somente leitura**: não é
  possível publicar novas memórias nem anexar fotos. As memórias já publicadas
  continuam visíveis. A regra vale no banco (`can_post_in_trip`, fuso
  `America/Sao_Paulo`) e na interface, que troca o composer por um aviso.
  Administradores da viagem continuam podendo moderar.
- Detalhe da viagem: roteiro, Padlet, dia a dia com anotações pessoais,
  checklist, contatos de emergência e avaliação.
- Pull-to-refresh, atualização manual e Realtime.
- `touch_last_seen()` registra o último acesso; `public_profiles` expõe apenas
  id + nome para os autores do mural.
- Falhas de configuração/rede exibem uma tela de erro em vez de travar.

## Perfil, histórico e RLS

O app compartilha o banco do painel `HomeroPassaporteADM`. As migrações
`20261023160000_client_history_and_inactive_users.sql`,
`20261023170000_client_ui_support.sql` e
`20261026090000_cpf_groups_trip_badges_wall_images.sql` (no repositório do ADM)
definem o modelo:

- `users.status = 'active'` → acesso completo às viagens do grupo atual.
- `users.status = 'inactive'` → sem acesso ao conteúdo do app. O cliente mostra
  a tela de conta inativa e as policies do Supabase também bloqueiam os dados.
- Quem participou de uma viagem continua com acesso ao histórico mesmo depois
  de sair do grupo: viagens publicadas ou encerradas, mural, anotações,
  avaliações e insígnias.
- `trip_participants` registra os participantes no momento em que a viagem é
  publicada (ou quando um grupo é vinculado a uma viagem já publicada). O
  histórico não depende mais do `group_id` atual do usuário.
- `user_badges` e `notifications` agora têm policies; antes estavam com RLS
  habilitado e sem nenhuma regra.
- `users.cpf` (único, 11 dígitos) e `users.must_change_password` controlam o
  login por CPF e a troca obrigatória. `cpf_auth_email()` documenta a conversão
  usada pelos apps e pela Edge Function `create-user`.
- `wall_post_images` guarda as fotos do Padlet; o bucket `wall-photos` é
  privado e as policies liberam upload apenas na pasta do próprio usuário e
  leitura para quem pode ver o post.

## Realtime

As tabelas usadas pelo cliente estão na publicação do projeto atual. Para um
ambiente novo:

```sql
alter publication supabase_realtime add table public.trips;
alter publication supabase_realtime add table public.trip_groups;
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.trip_participants;
alter publication supabase_realtime add table public.user_badges;
alter publication supabase_realtime add table public.badges;
alter publication supabase_realtime add table public.wall_posts;
alter publication supabase_realtime add table public.wall_post_images;
```

Sem esse passo, o app continua funcionando com atualização manual e
pull-to-refresh.

### Escopo das assinaturas

O Padlet assina `wall_posts` **filtrado por `trip_id`**: cada cliente recebe
apenas eventos da viagem que está aberta. Antes o canal escutava a tabela
inteira e cada publicação de qualquer viagem fazia todos os clientes
recarregarem o mural.

As recargas são agrupadas por um debounce de 350 ms, então uma publicação
com 4 fotos gera uma única consulta em vez de cinco.

`wall_post_images` não tem `trip_id`; por isso o cliente só reage a imagens
de posts que já estão carregados na viagem atual.

Ao trocar de viagem, o canal é recriado com o novo filtro.

## Capturas

- [Login](docs/screenshots/final_login_cpf.png)
- [Início](docs/screenshots/final_home.png)
- [Passaporte](docs/screenshots/final_passaporte.png)
- [Insígnias](docs/screenshots/final_insignias.png)
- [Padlet da viagem](docs/screenshots/final_padlet.png)
- [Perfil](docs/screenshots/final_perfil.png)
- [Detalhe — Roteiro](docs/screenshots/detail_roteiro.png)
- [Detalhe — Checklist](docs/screenshots/detail_checklist.png)
- [Detalhe — Contatos](docs/screenshots/detail_contatos.png)
- [Detalhe — Avaliação](docs/screenshots/detail_avaliacao.png)

## Publicação Android/iOS

- Android `applicationId`/`namespace`: `br.com.passaportebrasil.cliente`.
- iOS/macOS bundle ID: `br.com.passaportebrasil.cliente`.
- `android/key.properties` (veja `android/key.properties.example`) e o
  keystore são necessários para assinar o release. Sem eles, o build usa a
  chave de debug e **não deve ser publicado na Play Store**.
