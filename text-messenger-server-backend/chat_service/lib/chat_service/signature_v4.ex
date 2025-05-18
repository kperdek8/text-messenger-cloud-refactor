defmodule TextMessengerBackend.ChatService.AWS.SignatureV4 do
  @moduledoc """
  AWS Signature Version 4 implementation for Elixir.

  This module provides functionality to sign HTTP requests according to
  the AWS Signature Version 4 specification.

  ## Example usage:

      credentials = %{
        access_key: "your_access_key",
        secret_key: "your_secret_key",
        region: "us-east-1",
        service: "s3"
      }

      # For a GET request
      signed_request = AWS.SignatureV4.sign_request(
        "GET",
        "https://s3.amazonaws.com/my-bucket/my-file.txt",
        "",
        %{"Host" => "s3.amazonaws.com"},
        credentials
      )
  """

  @doc """
  Signs an HTTP request using AWS Signature Version 4.

  ## Parameters

  - `method`: HTTP method (e.g., "GET", "POST")
  - `url`: Full URL for the request
  - `body`: Request body (empty string for GET requests)
  - `headers`: Map of request headers
  - `credentials`: Map containing :access_key, :secret_key, :region, and :service

  ## Returns

  A map containing `:url`, `:headers`, and `:body` for the signed request.
  """
  def sign_request(method, url, body, headers, credentials) do
    uri = URI.parse(url)
    endpoint = uri.host
    request_path = uri.path || "/"
    query_params = URI.decode_query(uri.query || "")

    # Get the current timestamp in the required format
    amz_date = format_date_time(:basic)
    date_stamp = format_date(:basic)

    # Add required headers
    headers = headers
    |> Map.put("x-amz-date", amz_date)
    |> Map.put_new("Host", endpoint)

    # Create the canonical request
    canonical_request = create_canonical_request(
      method,
      request_path,
      query_params,
      headers,
      body
    )

    # Create the string to sign
    credential_scope = "#{date_stamp}/#{credentials.region}/#{credentials.service}/aws4_request"
    string_to_sign = create_string_to_sign(amz_date, credential_scope, canonical_request)

    # Calculate the signature
    signing_key = get_signature_key(
      credentials.secret_key,
      date_stamp,
      credentials.region,
      credentials.service
    )
    signature = hmac_hex(signing_key, string_to_sign)

    # Create the authorization header
    authorization_header = create_authorization_header(
      credentials.access_key,
      credential_scope,
      headers,
      signature
    )

    # Add the authorization header to the headers
    headers = Map.put(headers, "Authorization", authorization_header)

    # Return the signed request
    %{
      url: url,
      headers: headers,
      body: body
    }
  end

  @doc """
  Creates a canonical request string.
  """
  def create_canonical_request(method, path, query_params, headers, payload) do
    canonical_headers = canonical_headers(headers)
    signed_headers = signed_headers(headers)

    [
      method,
      canonical_uri(path),
      canonical_query_string(query_params),
      canonical_headers,
      signed_headers,
      hex_encode(hash(payload))
    ]
    |> Enum.join("\n")
  end

  @doc """
  Creates a string to sign.
  """
  def create_string_to_sign(amz_date, credential_scope, canonical_request) do
    [
      "AWS4-HMAC-SHA256",
      amz_date,
      credential_scope,
      hex_encode(hash(canonical_request))
    ]
    |> Enum.join("\n")
  end

  @doc """
  Creates the authorization header value.
  """
  def create_authorization_header(access_key, credential_scope, headers, signature) do
    signed_headers = signed_headers(headers)

    "AWS4-HMAC-SHA256 " <>
    "Credential=#{access_key}/#{credential_scope}, " <>
    "SignedHeaders=#{signed_headers}, " <>
    "Signature=#{signature}"
  end

  @doc """
  Derives the signing key.
  """
  def get_signature_key(key, date_stamp, region, service) do
    k_date = hmac("AWS4" <> key, date_stamp)
    k_region = hmac(k_date, region)
    k_service = hmac(k_region, service)
    hmac(k_service, "aws4_request")
  end

  # Helper functions

defp canonical_uri(path) do
  path
  |> String.split("/")
  |> Enum.map(fn segment -> URI.encode(segment, fn c -> c != ?/ end) end)
  |> Enum.join("/")
end

  defp canonical_query_string(params) when map_size(params) == 0, do: ""
  defp canonical_query_string(params) do
    params
    |> Enum.map(fn {k, v} -> {URI.encode_www_form(k), URI.encode_www_form(v)} end)
    |> Enum.sort()
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join("&")
  end

  defp canonical_headers(headers) do
    headers
    |> Enum.map(fn {name, value} -> {String.downcase(name), String.trim(value)} end)
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map(fn {name, value} -> "#{name}:#{value}\n" end)
    |> Enum.join("")
  end

  defp signed_headers(headers) do
    headers
    |> Enum.map(fn {name, _} -> String.downcase(name) end)
    |> Enum.sort()
    |> Enum.join(";")
  end

  defp format_date_time(:basic) do
    {{year, month, day}, {hour, min, sec}} = :calendar.universal_time()

    :io_lib.format(
      "~4..0B~2..0B~2..0BT~2..0B~2..0B~2..0BZ",
      [year, month, day, hour, min, sec]
    )
    |> List.to_string()
  end

  defp format_date(:basic) do
    {{year, month, day}, _} = :calendar.universal_time()

    :io_lib.format(
      "~4..0B~2..0B~2..0B",
      [year, month, day]
    )
    |> List.to_string()
  end

  defp hash(data) do
    :crypto.hash(:sha256, data)
  end

  defp hex_encode(binary) do
    Base.encode16(binary, case: :lower)
  end

  defp hmac(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

  defp hmac_hex(key, data) do
    hmac(key, data) |> hex_encode()
  end
end
