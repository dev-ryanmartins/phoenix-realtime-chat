defmodule PhoenixChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    belongs_to :user, PhoenixChat.Chat.User
    belongs_to :room, PhoenixChat.Chat.Room
    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :user_id, :room_id])
    |> validate_required([:body, :user_id, :room_id])
    |> validate_length(:body, min: 1, max: 1000)
  end
end
