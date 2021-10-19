defmodule SmartRentEx.Types.Me do
  use TypedStruct

  typedstruct do
    field(:id, Integer.t(), enforce: true)
    field(:email, String.t(), enforce: true)
    field(:first_name, String.t(), enforce: true)
    field(:last_name, String.t(), enforce: true)
    field(:mobile_phone, String.t(), enforce: true)
    field(:tos_accepted_at, Stirng.t(), enforce: true)
    field(:tos_accepted, boolean(), enforce: true)
  end
end
