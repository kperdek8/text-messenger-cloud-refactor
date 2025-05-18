defmodule TextMessengerBackend.NotificationServiceWeb.SqsConsumer do
  use Broadway

  alias Broadway.Message
  alias TextMessengerBackend.NotificationService.EventHandlers

  require Logger

  def start_link(_opts) do
	  Logger.info("Broadway SQS consumer started.")
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwaySQS.Producer,
                 queue_url: Application.get_env(:notification_service, :sqs)[:queue_url],
                 config: [
                  access_key_id: Application.get_env(:notification_service, :aws)[:access_key],
                  secret_access_key: Application.get_env(:notification_service, :aws)[:secret_key],
				          security_token: Application.get_env(:notification_service, :aws)[:token],
                  region: Application.get_env(:notification_service, :aws)[:region]],
				          wait_time_seconds: 1
                }
      ],
      processors: [
        default: [concurrency: 10]
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
      {:ok, %{"event" => "user.added_to_chat", "data" => data}} ->
		    Logger.info("Handling message")
        case EventHandlers.handle_user_added_to_chat(data) do
          :ok ->
            message
          {:error, reason} ->
            Logger.error("User added to chat handler failed: #{inspect(reason)}")
            Message.failed(message, "user_added_to_chat_failed")
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
