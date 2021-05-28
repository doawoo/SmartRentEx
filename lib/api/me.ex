defmodule SmartRentEx.API.Me do
  use Tesla

  alias SmartRentEx.Types.Me
  alias SmartRentEx.Types.Session

  plug(Tesla.Middleware.BaseUrl, "https://control.smartrent.com/api/v1/users/me")
  plug(Tesla.Middleware.Headers, [{"user-agent", "SmartRentEx - @doawoo"}])
  plug(Tesla.Middleware.JSON)

  @spec get_me(SmartRentEx.Types.Session.t()) :: {:error, any} | {:ok, SmartRentEx.Types.Me.t()}
  def get_me(%Session{socket_token: token}) do
    case get("/", headers: [{"authorization", "Bearer #{token}"}]) do
      {:ok, env} ->
        user = %Me{
          id: env.body["id"],
          first_name: env.body["first_name"],
          last_name: env.body["last_name"],
          email: env.body["email"],
          mobile_phone: env.body["mobile_phone"],
          tos_accepted_at: env.body["tos_accepted_at"],
          tos_accepted: env.body["tos_accepted"]
        }

        {:ok, user}

      err ->
        err
    end
  end
end
