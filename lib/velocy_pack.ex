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

  @doc """
  Generates VelocyPack corresponding to `input`.

  The generation is controlled by the `VelocyPack.Encoder` protocol,
  please refer to the module to read more on how to define the protocol
  for custom data types.

  The options parameter is reserved for future use and not used at the moment.
  """
  def encode(input, opts \\ []) do
    case VelocyPack.Encode.encode(input, opts) do
      {:ok, result} -> {:ok, IO.iodata_to_binary(result)}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Generates VelocyPack corresponding to `input`.

  Similar to `encode/2` except it will unwrap the error tuple and raise
  in case of errors.
  """
  def encode!(input, opts \\ []) do
    case encode(input, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
