defmodule SmartRentEx do
  alias SmartRentEx.Agent
  alias SmartRentEx.API.Sessions

  alias SmartRentEx.Types.Device
  alias SmartRentEx.Types.Hub

  @spec create_agent(binary, binary) :: :ignore | {:error, any} | {:ok, pid}
  def create_agent(email, password) when is_binary(email) and is_binary(password) do
    {:ok, session} = Sessions.new_session(email, password)
    GenServer.start_link(Agent, session)
  end

  def create_hoh_agent(email, password) when is_binary(email) and is_binary(password) do
    {:ok, agent} = create_agent(email, password)
    primary_hub = get_hubs(agent) |> List.first()
    :ok = connect_to_all_devices(agent, primary_hub)
    agent
  end

  @spec get_hubs(pid) :: list(Hub.t())
  def get_hubs(agent) when is_pid(agent) do
    GenServer.call(agent, :get_hubs)
  end

  @spec get_devices(pid, Hub.t()) :: list(Device.t())
  def get_devices(agent, %Hub{} = hub) when is_pid(agent) do
    GenServer.call(agent, {:get_devices, hub})
  end

  @spec connect_to_device(pid, SmartRentEx.Types.Device.t()) :: :ok
  def connect_to_device(agent, %Device{} = device) when is_pid(agent) do
    GenServer.cast(agent, {:connect_to_device, device})
  end

  @spec connect_to_all_devices(pid, Hub.t()) :: :ok
  def connect_to_all_devices(agent, %Hub{} = hub) when is_pid(agent) do
    device_list = get_devices(agent, hub)
    Enum.each(device_list, fn %Device{} = device ->
      connect_to_device(agent, device)
    end)
  end
end
