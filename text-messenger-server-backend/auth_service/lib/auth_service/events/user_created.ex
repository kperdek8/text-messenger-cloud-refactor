defmodule TextMessengerBackend.AuthService.Events.UserCreated do
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
            username: String.t(),
            email: String.t(),
            cognito_sub: String.t()
          }
        }

  @doc """
  Creates a new `UserCreated` event struct.
  """
  def new(user_attrs) when is_map(user_attrs) do
    %__MODULE__{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      event: "user.created",
      data: Map.take(user_attrs, [:id, :username, :email, :cognito_sub])
    }
  end
end