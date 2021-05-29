defmodule SmartRentEx.Agent do
  use GenServer

  alias PhoenixClient.Channel

  alias SmartRentEx.API
  alias SmartRentEx.Types.Device
  alias SmartRentEx.Types.Hub
  alias SmartRentEx.Types.Session

  require Logger

  @moduledoc """
  This is a high-level gen-server which handles events from the SmartRent API socket server
  It also stores a session with the RESTful API so you can query device information at will
  """

  @socket_base_url "wss://control.smartrent.com/socket/websocket?vsn=2.0.0"

  @impl GenServer
  def init(%Session{} = session) do
    Logger.info("SmartRentEx Agent Inint")

    socket = open_socket_connection(session)

    {:ok,
     %{
       session: session,
       socket: socket,
       callbacks: [],
       device_connections: %{}
     }}
  end

  #### Socket Sending Functions

  @impl GenServer
  def handle_cast({:set_device_attribute, %Device{} = device, attr_map}, state) do
    case Map.get(state.device_connections, device.id) do
      nil ->
        Logger.error("Cannot send attribute mesasge to device we're not connected to!")

      channel ->
        Logger.info(
          "Sending attribute message to device | id=#{device.id} msg=#{inspect(attr_map)}"
        )

        Channel.push(channel, "update_attributes", %{"attributes" => attr_map})
    end

    {:noreply, state}
  end

  #### Utility Functions

  defp open_socket_connection(session) do
    Logger.info("Attempting to connect to SmartRent socket server...")
    socket_opts = [url: @socket_base_url <> "&token=#{session.socket_token}"]
    {:ok, socket} = PhoenixClient.Socket.start_link(socket_opts)
    Logger.info("Connected to SmartRent socket server!")
    socket
  end

  #### Socket Message Callbacks

  @impl GenServer
  def handle_info(msg, state) do
    Enum.each(state.callbacks, fn mod -> mod.smartrent_event(msg) end)
    {:noreply, state}
  end

  #### Callback Registration Events

  @impl GenServer
  def handle_call({:add_callback_module, mod}, _from, state) when is_atom(mod) do
    Logger.info("Adding module #{mod} to SmartRent event callbacks...")
    {:reply, :ok, %{callbacks: [mod | state.callbacks]}}
  end

  #### Device Connection Functions

  def handle_call({:connect_to_device, %Device{} = device}, _from, state) do
    case Channel.join(state.socket, "devices:#{device.id}") do
      {:ok, _response, channel} ->
        Logger.info(
          "Connected to SmartRent device | id=#{device.id} name=#{device.name} type=#{device.type}",
          ansi_color: :green
        )

        {:reply, :ok,
         %{state | device_connections: Map.put_new(state.device_connections, device.id, channel)}}

      {:error, reason} ->
        Logger.error(
          "Failed to connect to SmartRent device | id=#{device.id} reason=#{inspect(reason)}"
        )

        {:reply, {:error, reason}, state}
    end
  end

  #### RESTful API Functions

  @impl GenServer
  def handle_call(:get_hubs, _from, state) do
    {:ok, hubs} = API.Hubs.list(state.session)
    {:reply, hubs, state}
  end

  @impl GenServer
  def handle_call({:get_devices, %Hub{} = hub}, _from, state) do
    {:ok, hubs} = API.Devices.list(state.session, hub.id)
    {:reply, hubs, state}
  end

  def handle_call({:get_device, %Hub{} = hub, device_id}, _from, state) do
    {:ok, device} = API.Devices.get_by_id(state.session, hub, device_id)
    {:reply, device, state}
  end

  def handle_call({:get_hub, hub_id}, _from, state) do
    {:ok, hub} = API.Hubs.get_by_id(state.session, hub_id)
    {:reply, hub, state}
  end
end
