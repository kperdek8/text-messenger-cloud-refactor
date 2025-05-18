defmodule TextMessengerBackend.ChatService.Events.UserAdded do
  @moduledoc """
  Standard event structure for user creation, with timestamp and event type.
  """

  @derive Jason.Encoder
  defstruct [
    :timestamp,
    :event,
    :data
  ]

  @type t :: %__MODULE__{
          timestamp: String.t(),
          event: String.t(),
          data: %{
            id: String.t(),
            chat_id: String.t()
          }
        }

  @doc """
  Creates a new `UserCreated` event struct.
  """
  def new(event_attrs) when is_map(event_attrs) do
    %__MODULE__{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      event: "user.added_to_chat",
      data: Map.take(event_attrs, [:id, :chat_id])
    }
  end
end
