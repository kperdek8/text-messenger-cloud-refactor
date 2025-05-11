defmodule AwsMockup.UsersCache do
  use GenServer

  ## Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_user(username, password) do
    GenServer.call(__MODULE__, {:add_user, username, password})
  end

  def get_password(username) do
    GenServer.call(__MODULE__, {:get_password, username})
  end

  def get_user_sub(username) do
    GenServer.call(__MODULE__, {:get_user_sub, username})
  end

  ## GenServer Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_user, username, password}, _from, state) do
    if Map.has_key?(state, username) do
      {:reply, {:error, :user_exists}, state}
    else
      user_sub = generate_user_sub()
      user_data = %{
        password: password,
        user_sub: user_sub,
        created_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
      {:reply, {:ok, user_sub}, Map.put(state, username, user_data)}
    end
  end

  def handle_call({:get_password, username}, _from, state) do
    case Map.get(state, username) do
      nil -> {:reply, {:error, :user_not_found}, state}
      %{password: password} -> {:reply, {:ok, password}, state}
    end
  end

  def handle_call({:get_user_sub, username}, _from, state) do
    case Map.get(state, username) do
      nil -> {:reply, {:error, :user_not_found}, state}
      %{user_sub: user_sub} -> {:reply, {:ok, user_sub}, state}
    end
  end

  defp generate_user_sub do
    UUID.uuid4()
  end
end
