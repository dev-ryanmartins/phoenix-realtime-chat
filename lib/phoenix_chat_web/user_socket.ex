defmodule PhoenixChatWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", PhoenixChatWeb.RoomChannel

  @impl true
  def connect(%{"user_id" => user_id}, socket, _connect_info) when is_integer(user_id) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  def connect(%{"user_id" => user_id}, socket, _connect_info) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {parsed_id, ""} -> {:ok, assign(socket, :user_id, parsed_id)}
      _ -> :error
    end
  end

  def connect(_, _, _), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
