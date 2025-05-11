defmodule TextMessengerClient.Cache do
  use GenServer

  alias TextMessengerClient.UsersAPI
  alias TextMessenger.Protobuf.User

  @username_cache_table :username_cache

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(@username_cache_table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  # Public API

  def put_username(user_id, username) do
    GenServer.cast(__MODULE__, {:put_username, user_id, username})
  end

  def get_username(user_id, token) do
    GenServer.call(__MODULE__, {:get_username, user_id, token})
  end

  # GenServer callbacks

  def handle_cast({:put_username, user_id, username}, state) do
    :ets.insert(@username_cache_table, {user_id, username})
    {:noreply, state}
  end

  def handle_call({:get_username, user_id, token}, _from, state) do
    case :ets.lookup(@username_cache_table, user_id) do
      [{_user_id, username}] ->
        {:reply, {:ok, username}, state}

      [] ->
        case UsersAPI.fetch_user(token, user_id) do
          %User{name: username} ->
            put_username(user_id, username)
            {:reply, {:ok, username}, state}

          {:error, _reason} ->
            {:reply, {:ok, "Unknown user"}, state}
        end
    end
  end
end