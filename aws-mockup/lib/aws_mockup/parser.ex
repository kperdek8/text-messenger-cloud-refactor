defmodule AwsMockup.Parsers.AmzJson do
  @behaviour Plug.Parsers

  def init(opts), do: opts

  def parse(conn, "application", "x-amz-json-1.1", headers, opts) do
    Plug.Parsers.JSON.parse(conn, "application", "json", headers, opts)
  end

  def parse(_conn, _type, _subtype, _headers, _opts), do: {:next, nil, nil}
end