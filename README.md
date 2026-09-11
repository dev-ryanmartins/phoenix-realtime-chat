# Lume — chat em tempo real com Phoenix

Lume é uma aplicação de chat com salas públicas, autenticação simples por nome
de exibição e mensagens entregues em tempo real por Phoenix Channels,
WebSockets e Phoenix PubSub.

## Requisitos

- Elixir 1.18+
- Erlang/OTP 27+
- Node.js (usado pelo esbuild e pelo Tailwind do Phoenix)

## Rodar localmente

```bash
cd phoenix_chat
mix setup
PORT=5000 mix phx.server
```

Abra [http://localhost:5000](http://localhost:5000). O comando `mix setup` cria
o banco SQLite em `phoenix_chat_dev.db`, executa as migrações, insere as salas
iniciais e compila os assets Tailwind/esbuild.

Para executar em outra porta:

```bash
PORT=4000 mix phx.server
```

O arquivo SQLite é local e não precisa de um serviço externo. Em produção,
configure `DATABASE_PATH`, `SECRET_KEY_BASE`, `PHX_HOST` e `PORT` conforme o
ambiente de execução.

## Como testar o tempo real

1. Abra o Lume em duas abas ou em duas janelas anônimas.
2. Entre com nomes diferentes.
3. Acesse a mesma sala pública, como `Geral`.
4. Envie uma mensagem em uma janela e observe a entrega instantânea na outra.
5. Troque de sala pela navegação lateral para testar os tópicos independentes.

Cada sala usa um tópico no formato `room:<slug>`. O `RoomChannel` carrega as
últimas mensagens ao entrar, persiste novas mensagens no SQLite e transmite o
evento `new_msg` para todos os sockets conectados naquele tópico.

## Migrações, seeds e testes

```bash
# Criar/atualizar o banco e popular salas
mix ecto.setup

# Rodar apenas migrações pendentes
mix ecto.migrate

# Recriar o banco de desenvolvimento
mix ecto.reset

# Formatar e executar testes
mix format
mix test
```

Os testes usam um banco SQLite separado (`phoenix_chat_test.db`) e sandbox do
Ecto. Para testar manualmente os canais, o fluxo com duas abas acima é
suficiente; o navegador abre um WebSocket em `/socket` e envia o `user_id`
assinado na sessão para o `UserSocket`.

## Estrutura principal

- `lib/phoenix_chat/chat.ex` — regras de usuários, salas e mensagens.
- `lib/phoenix_chat/chat/` — schemas Ecto de `User`, `Room` e `Message`.
- `lib/phoenix_chat_web/room_channel.ex` — canal Phoenix para cada sala.
- `lib/phoenix_chat_web/user_socket.ex` — autenticação do socket por sessão.
- `lib/phoenix_chat_web/presence.ex` — presença por sala com PubSub.
- `lib/phoenix_chat/activity_logger.ex` — GenServer concorrente que registra
  entradas, saídas e mensagens sem bloquear o canal.
- `assets/js/app.js` — cliente Phoenix Socket e renderização das mensagens.
- `priv/repo/migrations/` — schema SQLite e índices.

## Stack

- Phoenix 1.8.13
- Phoenix Channels e Phoenix PubSub
- Ecto SQL + SQLite3
- Tailwind CSS + esbuild
- Bandit
- GenServer para atividade em segundo plano