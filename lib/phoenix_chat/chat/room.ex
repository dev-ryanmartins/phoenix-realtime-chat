defmodule PhoenixChat.Chat.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :position, :integer, default: 0
    has_many :messages, PhoenixChat.Chat.Message
    timestamps(type: :utc_datetime)
  end

  def changeset(room, attrs) do
    room
    |> cast(attrs, [:slug, :name, :description, :position])
    |> validate_required([:slug, :name, :description])
    |> unique_constraint(:slug)
  end
end
