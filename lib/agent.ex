defmodule SmartRentEx.Agent do
  use GenServer

  alias PhoenixClient.Channel

  alias SmartRentEx.API
  alias SmartRentEx.Types.Device
  alias SmartRentEx.Types.Hub
  alias SmartRentEx.Types.Session

  require Logger

  @send_timeout 10_0000

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
       active_hub: nil,
       callbacks: [],
       device_connections: %{}
     }}
  end

  #### Socket Sending Functions

  @impl GenServer
  def handle_cast({:set_device_attribute, %Device{} = device, name, value}, state) do
    case Map.get(state.device_connections, device.id) do
      nil ->
        Logger.error("Cannot send attribute mesasge to device we're not connected to!")

      channel ->
        Logger.info(
          "Sending attribute message to device | id=#{device.id} attribute_name=#{name} attribute value=#{
            value
          }"
        )

        Channel.push(
          channel,
          "update_attributes",
          %{"attributes" => [%{"name" => name, "value" => value}]},
          @send_timeout
        )
    end

    {:noreply, state}
  end

  #### CATCH ALL BECAUSE LOL ####
  def handle_cast(unknown_message, state) do
    Logger.error("Got a cast we don't know how to handle | message=#{inspect(unknown_message)}")
    {:reply, :error, state}
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
  # Takes incoming messages from the SmartRent sockets and forwards them to callback modules
  def handle_info(msg, state) do
    Enum.each(state.callbacks, fn mod -> mod.smartrent_event(msg, self()) end)
    {:noreply, state}
  end

  #### Callback Registration Events

  @impl GenServer
  # Add a module to the event callback list, when an event is notices from SmartRent it will be
  # forwarded to ModuleName.smartrent_event/2 with the message and pid of the agent as the arguments
  def handle_call({:add_callback_module, mod}, _from, state) when is_atom(mod) do
    Logger.info("Adding module #{mod} to SmartRent event callbacks...")
    {:reply, :ok, %{state | callbacks: [mod | state.callbacks]}}
  end

  #### Device Connection Functions

  # Connect to a device topic by ID
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

  # Sets the active hub by ID
  def handle_call({:set_active_hub, hub_id}, _from, state) do
    with {:ok, hubs} <- API.Hubs.list(state.session),
         %Hub{} = found <- Enum.find(hubs, fn h -> h.id == hub_id end) do
      {:reply, :ok, %{state | active_hub: found}}
    else
      _ -> {:reply, :error, state}
    end
  end

  # Sets the active hub by picking the first one in the list
  def handle_call(:set_active_hub, _from, state) do
    with {:ok, hubs} <- API.Hubs.list(state.session),
         %Hub{} = first_hub <- List.first(hubs) do
      {:reply, :ok, %{state | active_hub: first_hub}}
    else
      _ -> {:reply, :error, state}
    end
  end

  #### RESTful API Functions

  @impl GenServer
  # Get list of hubs
  def handle_call(:get_hubs, _from, state) do
    {:ok, hubs} = API.Hubs.list(state.session)
    {:reply, hubs, state}
  end

  # Get device list from specific Hub
  def handle_call({:get_devices, %Hub{} = hub}, _from, state) do
    {:ok, hubs} = API.Devices.list(state.session, hub.id)
    {:reply, hubs, state}
  end

  # Get device list from currently active Hub
  def handle_call(:get_devices, _from, %{active_hub: %Hub{}} = state) do
    {:ok, devices} = API.Devices.list(state.session, state.active_hub.id)
    {:reply, devices, state}
  end

  def handle_call(:get_devices, _from, %{active_hub: nil} = state), do: {:reply, [], state}

  # Get device by ID list from specific Hub
  def handle_call({:get_device, %Hub{} = hub, device_id}, _from, state) do
    {:ok, device} = API.Devices.get_by_id(state.session, hub, device_id)
    {:reply, device, state}
  end

  # Get device by ID list from currently active Hub
  def handle_call({:get_device, device_id}, _from, %{active_hub: %Hub{}} = state) do
    {:ok, device} = API.Devices.get_by_id(state.session, state.active_hub.id, device_id)
    {:reply, device, state}
  end

  def handle_call(:get_device, _from, %{active_hub: nil} = state), do: {:reply, nil, state}

  # Get hub by ID
  def handle_call({:get_hub, hub_id}, _from, state) do
    {:ok, hub} = API.Hubs.get_by_id(state.session, hub_id)
    {:reply, hub, state}
  end

  #### CATCH ALL BECAUSE LOL ####
  def handle_call(unknown_message, from, state) do
    Logger.error(
      "Got a message we don't know how to handle from #{inspect(from)} | message=#{
        inspect(unknown_message)
      }"
    )

    {:reply, :error, state}
  end
end
