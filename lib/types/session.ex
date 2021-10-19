defmodule SmartRentEx.Types.Session do
  use TypedStruct

  typedstruct do
    field(:aws_lb, String.t(), enforce: true)
    field(:aws_cors, String.t(), enforce: true)
    field(:server_key, String.t(), enforce: true)
    field(:socket_token, String.t(), enforce: true)
  end
end
