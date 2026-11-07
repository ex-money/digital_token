defmodule DigitalToken.Config do
  @moduledoc false

  @doc """
  Return the json module: OTP's `:json`, from OTP 27 on. Only the
  data update task decodes JSON; the library reads its bundled ETF
  data on any supported OTP release.

  """
  def json_library do
    :json
  end
end
