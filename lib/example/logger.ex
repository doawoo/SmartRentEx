defmodule SmartRentEx.Example.Logger do
  alias PhoenixClient.Message

  require Logger

  @behaviour SmartRentEx.CallbackModule

  def smartrent_event(%Message{event: "attribute_state", payload: payload}) do
    :ok = Logger.info("Attribute changed on SmartRent device | #{inspect(payload)}")
  end
  def smartrent_event(_), do: nil
end
