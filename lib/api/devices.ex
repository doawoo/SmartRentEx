defmodule SmartRentEx.API.Devices do
  use Tesla

  alias SmartRentEx.Types.Device
  alias SmartRentEx.Types.Session

  plug(Tesla.Middleware.BaseUrl, "https://control.smartrent.com/api/v1/hubs/")
  plug(Tesla.Middleware.Headers, [{"user-agent", "SmartRentEx - @doawoo"}])
  plug(Tesla.Middleware.JSON)

  @spec list(SmartRentEx.Types.Session.t(), any) :: {:error, any} | {:ok, list(Device.t())}
  def list(%Session{socket_token: token}, hub_id) do
    case get("/#{hub_id}/devices/", headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, env} ->
        if env.body["data"] do
          hubs = Enum.reduce(env.body["data"], [], &parse_device/2)
          {:ok, hubs}
        else
          {:error, :nil_data}
        end
      err -> err
    end
  end

  @spec get_by_id(SmartRentEx.Types.Session.t(), any, any) :: {:error, any} | {:ok, Device.t()}
  def get_by_id(%Session{socket_token: token}, hub_id, dev_id) do
    case get("/#{hub_id}/devices/#{dev_id}", headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, env} ->
        if env.body["data"] do
          [hub] = parse_device(env.body["data"])
          {:ok, hub}
        else
          {:error, :nil_data}
        end
      err -> err
    end
  end

  defp parse_device(device_data, acc \\ []) do
    device = %Device{
      id: device_data["id"],
      attributes: Enum.map(device_data["attributes"], fn {k,v} -> {k,v} end),
      battery_level: device_data["battery_level"],
      battery_powered: device_data["battery_powered"],
      icon: device_data["icon"],
      name: device_data["name"],
      online: device_data["online"],
      pending_update: device_data["pending_update"],
      primary_lock: device_data["primary_lock"],
      room: device_data["room"],
      show_on_dashboard: device_data["show_on_dashboard"],
      type: device_data["type"],
      valid_config: device_data["valid_config"],
      warning: device_data["warning"]
    }
    [device | acc]
  end
end
