defmodule ExAws.Request.Finch do
  @moduledoc """
  ExAws HTTP client implementation for Finch.
  """

  @behaviour ExAws.Request.HttpClient

  @finch_name TextMessengerBackend.FileService.Finch

  # Make sure Finch is started in your supervision tree:
  # {Finch, name: MyFinch}

  @impl ExAws.Request.HttpClient
  def request(method, url, body, headers, _http_opts) do
    finch_request = Finch.build(method, url, headers, body)

    case Finch.request(finch_request, @finch_name) do
      {:ok, %Finch.Response{status: status_code, headers: resp_headers, body: resp_body}} ->
        {:ok, %{status_code: status_code, headers: resp_headers, body: resp_body}}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end
end
