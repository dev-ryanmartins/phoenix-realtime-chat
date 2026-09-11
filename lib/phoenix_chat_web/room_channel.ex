defmodule PhoenixChatWeb.RoomChannel do
  use PhoenixChatWeb, :channel

  alias PhoenixChat.Chat
  alias PhoenixChat.Chat.Room
  alias PhoenixChat.ActivityLogger
  alias PhoenixChat.Repo
  alias PhoenixChatWeb.Presence

  @impl true
  def join("room:" <> slug, _payload, socket) do
    with %Room{} = room <- Chat.get_room_by_slug(slug),
         user when not is_nil(user) <- get_user(socket) do
      send(self(), {:after_join, room, user})

      {:ok,
       %{
         messages: Chat.list_messages(room.id) |> Enum.map(&Chat.serialize_message/1),
         member_count: member_count("room:" <> slug)
       }, assign(socket, room: room, user: user)}
    else
      _ -> {:error, %{reason: "room_not_found"}}
    end
  end

  @impl true
  def handle_info({:after_join, room, user}, socket) do
    Presence.track(self(), socket.topic, user.id, %{display_name: user.display_name})
    ActivityLogger.record(%{type: :joined, room: room.slug, user: user.display_name})
    broadcast_presence(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) when is_binary(body) do
    body = String.trim(body)

    if body == "" do
      {:reply, {:error, %{reason: "empty_message"}}, socket}
    else
      case Chat.create_message(socket.assigns.room, socket.assigns.user, body) do
        {:ok, message} ->
          payload = Chat.serialize_message(message)

          ActivityLogger.record(%{
            type: :message,
            room: socket.assigns.room.slug,
            user: socket.assigns.user.display_name
          })

          broadcast!(socket, "new_msg", payload)
          {:noreply, socket}

        {:error, _changeset} ->
          {:reply, {:error, %{reason: "message_not_saved"}}, socket}
      end
    end
  end

  def handle_in("new_msg", _payload, socket) do
    {:reply, {:error, %{reason: "invalid_message"}}, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if Map.has_key?(socket.assigns, :room) do
      ActivityLogger.record(%{
        type: :left,
        room: socket.assigns.room.slug,
        user: socket.assigns.user.display_name
      })
    end

    :ok
  end

  defp get_user(socket), do: Repo.get(PhoenixChat.Chat.User, socket.assigns.user_id)

  defp member_count(topic), do: map_size(Presence.list(topic))

  defp broadcast_presence(socket) do
    broadcast!(socket, "presence", %{count: member_count(socket.topic)})
  end
end
