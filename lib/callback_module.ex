defmodule SmartRentEx.CallbackModule do
  alias PhoenixClient.Message

  @callback smartrent_event(Message.t(), pid()) :: any
end
