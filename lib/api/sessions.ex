defmodule SmartRentEx.API.Sessions do
  use Tesla

  alias SmartRentEx.Types.Session

  @aws_lb_prefix "AWSALB="
  @aws_cors_prefix "AWSALBCORS="
  @session_token_prefix "_server_key="

  @token_regex ~r/window.websocketAccessToken = "([^"]*)"+/
  @token_html_url "https://control.smartrent.com/resident"

  plug(Tesla.Middleware.BaseUrl, "https://control.smartrent.com/authentication/sessions/")
  plug(Tesla.Middleware.Headers, [{"user-agent", "SmartRentEx - @doawoo"}])
  plug(Tesla.Middleware.JSON)

  def new_session(email, password) do
    case post("/", %{email: email, password: password}) do
      {:ok, env} ->
        cookies =
          Enum.filter(env.headers, fn {header_name, _value} -> header_name == "set-cookie" end)

        server_key =
          Enum.find(cookies, nil, fn {_header_name, value} ->
            String.starts_with?(value, @session_token_prefix)
          end)
          |> clean_cookie(@session_token_prefix)

        lb_key =
          Enum.find(cookies, nil, fn {_header_name, value} ->
            String.starts_with?(value, @aws_lb_prefix)
          end)
          |> clean_cookie(@aws_lb_prefix)

        cors_key =
          Enum.find(cookies, nil, fn {_header_name, value} ->
            String.starts_with?(value, @aws_cors_prefix)
          end)
          |> clean_cookie(@aws_cors_prefix)

        if server_key do
          session =
            %Session{
              server_key: server_key,
              aws_lb: lb_key,
              aws_cors: cors_key,
              socket_token: nil
            }
            |> get_socket_token()

          {:ok, session}
        else
          {:error, :login_failed}
        end

      {:error, _} ->
        {:error, :login_failed}
    end
  end

  defp clean_cookie(cookie, prefix) do
    {_header_name, value} = cookie

    String.replace(value, prefix, "")
    |> String.split(";")
    |> List.first()
  end

  defp get_socket_token(session) do
    headers = [
      {"Cookie", "AWSLB=#{session.aws_lb}"},
      {"Cookie", "AWSLBCORS=#{session.aws_cors}"},
      {"Cookie", "_server_key=#{session.server_key}"}
    ]

    case Tesla.get(@token_html_url, headers: headers) do
      {:ok, env} ->
        token =
          Regex.run(@token_regex, env.body)
          |> List.last()

        %Session{session | socket_token: token}

      _err ->
        session
    end
  end
end
