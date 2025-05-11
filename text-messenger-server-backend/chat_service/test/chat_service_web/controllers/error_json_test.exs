defmodule TextMessengerBackend.ChatServiceWeb.ErrorJSONTest do
  use TextMessengerBackend.ChatServiceWeb.ConnCase, async: true

  test "renders 404" do
    assert TextMessengerBackend.ChatServiceWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TextMessengerBackend.ChatServiceWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
