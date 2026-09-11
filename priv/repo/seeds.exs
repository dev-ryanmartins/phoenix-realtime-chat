alias PhoenixChat.Chat.Room
alias PhoenixChat.Repo

rooms = [
  %{slug: "general", name: "Geral", description: "Conversas do dia a dia", position: 1},
  %{
    slug: "ideias",
    name: "Ideias",
    description: "Rascunhos, perguntas e possibilidades",
    position: 2
  },
  %{slug: "cafe", name: "Café", description: "Pausa rápida para trocar uma ideia", position: 3}
]

Enum.each(rooms, fn attrs ->
  %Room{}
  |> Room.changeset(attrs)
  |> Repo.insert!(on_conflict: :nothing, conflict_target: [:slug])
end)
