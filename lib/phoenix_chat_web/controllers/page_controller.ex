defmodule PhoenixChatWeb.PageController do
  use PhoenixChatWeb, :controller

  alias PhoenixChat.Chat

  def home(conn, _params) do
    if get_session(conn, :user_id) do
      redirect(conn, to: ~p"/chat/general")
    else
      render(conn, :home, rooms: Chat.list_rooms(), page_title: "Entrar no Lume")
    end
  end

  def login(conn, %{"display_name" => display_name}) do
    case Chat.find_or_create_user(display_name) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Bem-vindo ao Lume, #{user.display_name}.")
        |> redirect(to: ~p"/chat/general")

      {:error, :invalid_name} ->
        conn
        |> put_flash(:error, "Escolha um nome entre 2 e 24 caracteres.")
        |> redirect(to: ~p"/")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  def room(conn, %{"slug" => slug}) do
    case get_session(conn, :user_id) do
      nil ->
        redirect(conn, to: ~p"/")

      user_id ->
        case Chat.get_room_by_slug(slug) do
          nil ->
            conn
            |> put_flash(:error, "Essa sala não existe.")
            |> redirect(to: ~p"/chat/general")

          room ->
            user = Chat.get_user!(user_id)

            render(conn, :room,
              room: room,
              rooms: Chat.list_rooms(),
              user: user,
              page_title: "#{room.name} · Lume"
            )
        end
    end
  end
end
