defmodule SmartRentEx.CallbackModule do
  alias PhoenixClient.Message

  @callback smartrent_event(Message.t()) :: any
end
