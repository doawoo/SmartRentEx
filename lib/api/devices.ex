defmodule SmartRentEx.API.Devices do
  use Tesla

  alias SmartRentEx.Types.Me
  alias SmartRentEx.Types.Session

  plug(Tesla.Middleware.BaseUrl, "https://control.smartrent.com/api/v1/users/me")
  plug(Tesla.Middleware.Headers, [{"user-agent", "SmartRentEx - @doawoo"}])
  plug(Tesla.Middleware.JSON)

end
