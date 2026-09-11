defmodule PhoenixChat.Chat.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :display_name, :string
    has_many :messages, PhoenixChat.Chat.Message
    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name])
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 2, max: 24)
    |> unique_constraint(:display_name)
  end
end
