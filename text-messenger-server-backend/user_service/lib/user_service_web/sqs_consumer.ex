defmodule TextMessengerBackend.UserServiceWeb.SqsConsumer do
  use Broadway

  alias Broadway.Message
  alias TextMessengerBackend.UserService.EventHandlers

  require Logger

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwaySQS.Producer,
                 queue_url: Application.get_env(:user_service, :sqs)[:queue_url],
                 config: [
                  access_key_id: Application.get_env(:user_service, :aws)[:access_key],
                  secret_access_key: Application.get_env(:user_service, :aws)[:secret_key],
                  region: Application.get_env(:user_service, :aws)[:region]]
                }
      ],
      processors: [
        default: []
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 2000
        ]
      ]
    )
  end

  def handle_message(_processor, %Message{data: raw_json} = message, _context) do
    case Jason.decode(raw_json) do
      {:ok, %{"event" => "user.created", "data" => user_data}} ->
        case EventHandlers.handle_user_created(user_data) do
          :ok ->
            message
          {:error, reason} ->
            Logger.error("User creation handler failed: #{inspect(reason)}")
            Message.failed(message, "user_creation_failed")
        end
      _ ->
        Logger.error("Invalid or unsupported message format: #{inspect(raw_json)}")
        Message.failed(message, "unhandled_event")
    end
  end

  def handle_batch(:default, messages, _batch_info, context) do
    Enum.map(messages, fn message ->
      handle_message(:default, message, context)
    end)
  end
end
