  defmodule TextMessengerBackend.FileService.FileAccess do
    @expires_in 60*60*2 # 2 hours
    def bucket, do: Application.get_env(:file_service, :s3)[:bucket]

    def generate_presigned_get_url(key) do
      opts = [expires_in: @expires_in]
      IO.inspect(bucket())
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(:get, bucket(), key, opts)
    end

    def generate_presigned_put_url(key, content_type \\ "application/octet-stream") do
      config = ExAws.Config.new(:s3)
      headers = [{"Content-Type", content_type}]
      opts = [virtual_host: false, expires_in: @expires_in, headers: headers]
      ExAws.S3.presigned_url(config, :put, bucket(), key, opts)
    end

    def object_exists?(key) do
      case ExAws.S3.head_object(bucket(), key) |> ExAws.request() do
        {:ok, _} -> true
        {:error, {:http_error, 404, _}} -> false
        {:error, error} -> IO.inspect(error)
          raise "Unexpected error checking S3 object"
      end
    end
  end
