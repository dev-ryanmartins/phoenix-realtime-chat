defmodule PhoenixChatWeb.PageControllerTest do
  use PhoenixChatWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Qual nome você quer usar?"
  end
end
