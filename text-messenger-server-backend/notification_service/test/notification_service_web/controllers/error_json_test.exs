defmodule TextMessengerBackend.NotificationServiceWeb.ErrorJSONTest do
  use TextMessengerBackend.NotificationServiceWeb.ConnCase, async: true

  test "renders 404" do
    assert TextMessengerBackend.NotificationServiceWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TextMessengerBackend.NotificationServiceWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
