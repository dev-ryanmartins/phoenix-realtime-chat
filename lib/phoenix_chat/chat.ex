defmodule PhoenixChat.Chat do
  @moduledoc """
  The chat domain: users, public rooms and persisted messages.
  """

  import Ecto.Query

  alias PhoenixChat.Chat.{Message, Room, User}
  alias PhoenixChat.Repo

  def list_rooms do
    Repo.all(from room in Room, order_by: [asc: room.position, asc: room.name])
  end

  def get_room_by_slug(slug), do: Repo.get_by(Room, slug: slug)

  def get_user!(id), do: Repo.get!(User, id)

  def find_or_create_user(display_name) when is_binary(display_name) do
    normalized_name = String.trim(display_name)

    if String.length(normalized_name) in 2..24 do
      case Repo.get_by(User, display_name: normalized_name) do
        nil ->
          %User{}
          |> User.changeset(%{display_name: normalized_name})
          |> Repo.insert()

        user ->
          {:ok, user}
      end
    else
      {:error, :invalid_name}
    end
  end

  def find_or_create_user(_), do: {:error, :invalid_name}

  def list_messages(room_id, limit \\ 60) do
    Message
    |> where([message], message.room_id == ^room_id)
    |> order_by([message], desc: message.inserted_at)
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
    |> Enum.reverse()
  end

  def create_message(room, user, body) do
    %Message{}
    |> Message.changeset(%{body: body, room_id: room.id, user_id: user.id})
    |> Repo.insert()
    |> case do
      {:ok, message} -> {:ok, Repo.preload(message, :user)}
      error -> error
    end
  end

  def serialize_message(%Message{} = message) do
    %{
      id: message.id,
      body: message.body,
      inserted_at: DateTime.to_iso8601(message.inserted_at),
      user: %{id: message.user.id, display_name: message.user.display_name}
    }
  end
end
