defmodule TextMessengerBackend.FileServiceWeb.ErrorJSONTest do
  use TextMessengerBackend.FileServiceWeb.ConnCase, async: true

  test "renders 404" do
    assert TextMessengerBackend.FileServiceWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TextMessengerBackend.FileServiceWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
