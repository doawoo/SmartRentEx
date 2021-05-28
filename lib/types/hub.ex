defmodule SmartRentEx.Types.Hub do
  use TypedStruct

  typedstruct do
    field :id, Integer.t(), enforce: true
    field :unit_id, Integer.t(), enforce: true
    field :online, boolean(), enforce: true
    field :connection, String.t(), enforce: true
    field :timezone, term(), enforce: true
    field :connected_to_community_wifi, boolean(), enforce: true
    field :wifi_supported, boolean(), enforce: true
    field :wifi_v2_supported, boolean(), enforce: true
  end
end
