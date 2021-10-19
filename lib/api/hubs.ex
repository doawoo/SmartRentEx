defmodule SmartRentEx.API.Hubs do
  use Tesla

  alias SmartRentEx.Types.Session
  alias SmartRentEx.Types.Hub

  plug(Tesla.Middleware.BaseUrl, "https://control.smartrent.com/api/v1/hubs/")
  plug(Tesla.Middleware.Headers, [{"user-agent", "SmartRentEx - @doawoo"}])
  plug(Tesla.Middleware.JSON)

  @spec list(SmartRentEx.Types.Session.t()) :: {:error, any} | {:ok, list(Hub.t())}
  def list(%Session{socket_token: token}) do
    case get("/", headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, env} ->
        if env.body["data"] do
          hubs = Enum.reduce(env.body["data"], [], &parse_hub/2)
          {:ok, hubs}
        else
          {:error, :nil_data}
        end

      err ->
        err
    end
  end

  @spec get_by_id(SmartRentEx.Types.Session.t(), any) :: {:error, any} | {:ok, Hub.t()}
  def get_by_id(%Session{socket_token: token}, hub_id) do
    case get("/#{hub_id}", headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, env} ->
        if env.body["data"] do
          [hub] = parse_hub(env.body["data"])
          {:ok, hub}
        else
          {:error, :nil_data}
        end

      err ->
        err
    end
  end

  defp parse_hub(hub_data, acc \\ []) do
    hub = %Hub{
      id: hub_data["id"],
      unit_id: hub_data["unit_id"],
      online: hub_data["online"],
      connection: hub_data["connection"],
      timezone: hub_data["timezone"],
      connected_to_community_wifi: hub_data["connected_to_community_wifi"],
      wifi_supported: hub_data["wifi_supported"],
      wifi_v2_supported: hub_data["wifi_v2_supported"]
    }

    [hub | acc]
  end
end
