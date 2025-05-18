defmodule TextMessengerBackend.NotificationService.EmailNotifier do
  require Logger

  def topic_arn(), do: Application.get_env(:notification_service, :sns)[:email_topic_arn]
  def table_name(), do: Application.get_env(:notification_service, :dynamodb)[:table_name]

  def send_email(subject, message) do
    id = UUID.uuid4()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    ExAws.SNS.publish(message,
      topic_arn: topic_arn(),
      message_structure: "string",
      subject: subject
    )
    |> ExAws.request()
    |> case do
      {:ok, response} ->
        Logger.info("Email notification sent: #{inspect(response)}")
        log_notification(id, subject, message, "sent", timestamp)
        :ok

      {:error, reason} ->
        Logger.error("Failed to send email: #{inspect(reason)}")
        log_notification(id, subject, message, "failed", timestamp)
        {:error, reason}
    end
  end

  defp log_notification(id, subject, message, status, timestamp) do
    ExAws.Dynamo.put_item(table_name(), %{
      "id" => id,
      "subject" => subject,
      "message" => message,
      "status" => status,
      "timestamp" => timestamp
    })
    |> ExAws.request()
    |> case do
      {:ok, _} -> Logger.info("Notification logged.")
      {:error, err} -> Logger.error("Failed to log notification: #{inspect(err)}")
    end
  end
end
