defmodule VelocyPack do
  @moduledoc """
  An Elixir parser and generator for [VelocyPack](https://github.com/arangodb/velocypack).
  """

  @doc """
  Parses the VelocyPack value from `input` iodata.

  The options parameter is reserved for future use and not used at the moment.
  """
  def decode(input, opts \\ []), do:
    VelocyPack.Decoder.parse(IO.iodata_to_binary(input), opts)

  @doc """
  Parses the VelocyPack value from `input` iodata.

  Similar to `decode/2` except it will unwrap the error tuple and raise
  in case of errors.
  """
  def decode!(input, opts \\ []) do
    case decode(input, opts) do
      {:ok, value} -> value
      {:error, err} -> raise err
    end
  end
end
