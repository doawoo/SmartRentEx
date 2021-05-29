defmodule SmartRentEx.Agent do
  use GenServer

  alias PhoenixClient.{Channel, Message}

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
  @spec init(SmartRentEx.Types.Session.t()) ::
          {:ok, %{device_connections: %{}, session: SmartRentEx.Types.Session.t(), socket: pid}}
  def init(%Session{} = session) do
    Logger.info("SmartRentEx Agent Inint")

    socket = open_socket_connection(session)
    {:ok, %{
      session: session,
      socket: socket,
      device_connections: %{},
    }}
  end

  @impl GenServer
  def handle_cast({:connect_to_device, %Device{} = device}, state) do
    case Channel.join(state.socket, "devices:#{device.id}") do
      {:ok, _response, channel} ->
        Logger.info("Connecting to SmartRent device | id=#{device.id} name=#{device.name} type=#{device.type}")
        {:noreply, %{state | device_connections: Map.put_new(state.device_connections, device.id, channel)}}
      {:error, reason} ->
        Logger.error("Failed to connect to SmartRent device | reason=#{inspect(reason)}")
        {:noreply, state}
    end

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
  def handle_info(%Message{event: "attribute_state", payload: payload}, state) do
    Logger.info("Attribute changed on SmartRent device | #{inspect(payload)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.warning("Got an unknow message type: #{inspect(msg)}")
    {:noreply, state}
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
