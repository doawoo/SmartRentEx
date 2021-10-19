defmodule SmartRentEx.Types.Device do
  use TypedStruct

  typedstruct do
    field(:id, Integer.t(), enforce: true)
    field(:attributes, list(Tuple.t()), enforce: true)
    field(:battery_level, Integer.t(), enforce: true)
    field(:battery_powered, boolean(), enforce: true)
    field(:icon, term(), enforce: true)
    field(:name, String.t(), enforce: true)
    field(:online, boolean(), enforce: true)
    field(:pending_update, boolean(), enforce: true)
    field(:primary_lock, boolean(), enforce: true)
    field(:room, map(), enforce: true)
    field(:show_on_dashboard, boolean(), enforce: true)
    field(:type, String.t(), enforce: true)
    field(:valid_config, boolean(), enforce: true)
    field(:warning, boolean(), enforce: true)
  end
end
