defmodule PhoenixChat.ActivityLogger do
  @moduledoc """
  Small supervised process used to record activity without blocking channels.
  """

  use GenServer
  require Logger

  @max_entries 80

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def record(event), do: GenServer.cast(__MODULE__, {:record, event})
  def recent, do: GenServer.call(__MODULE__, :recent)

  @impl true
  def init(_) do
    {:ok, %{entries: []}}
  end

  @impl true
  def handle_cast({:record, event}, state) do
    entry = Map.put(event, :at, DateTime.utc_now())
    Logger.info("[activity] #{format_event(entry)}")
    {:noreply, %{state | entries: Enum.take([entry | state.entries], @max_entries)}}
  end

  @impl true
  def handle_call(:recent, _from, state), do: {:reply, state.entries, state}

  defp format_event(%{type: type, room: room, user: user}) do
    "#{type} user=#{user} room=#{room}"
  end

  defp format_event(%{type: type}), do: to_string(type)
end
