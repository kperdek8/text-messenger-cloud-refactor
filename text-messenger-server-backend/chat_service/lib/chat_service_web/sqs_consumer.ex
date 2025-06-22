defmodule TextMessengerBackend.ChatServiceWeb.SqsConsumer do
  use Broadway

  alias Broadway.Message
  alias TextMessengerBackend.ChatService.EventHandlers

  require Logger

  def start_link(_opts) do
	Logger.info("Broadway SQS consumer started.")
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwaySQS.Producer,
                 queue_url: Application.get_env(:chat_service, :sqs)[:chat_created_queue_url],
                 config: [
                  access_key_id: Application.get_env(:chat_service, :aws)[:access_key],
                  secret_access_key: Application.get_env(:chat_service, :aws)[:secret_key],
				          security_token: Application.get_env(:chat_service, :aws)[:session_token],
                  region: Application.get_env(:chat_service, :aws)[:region]],
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
      {:ok, %{"event" => "chat.created", "data" => data}} ->
		    Logger.info("Handling message")
        case EventHandlers.handle_chat_created(data) do
          :ok ->
            message
          {:error, reason} ->
            Logger.error("Chat creation handler failed: #{inspect(reason)}")
            Message.failed(message, "#{reason}")
        end
      {:ok, %{"event" => other_event}} ->
        Logger.info("Ignoring unsupported event: #{other_event}")
        message
      {:error, _} ->
        Logger.error("Invalid JSON format: #{inspect(raw_json)}")
        Message.failed(message, "json_decode_failed")
    end
  end

  def handle_batch(:default, messages, _batch_info, context) do
    messages
  end
end
