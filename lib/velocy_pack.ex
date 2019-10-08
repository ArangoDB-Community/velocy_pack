defmodule VelocyPack do
  @moduledoc File.read!("#{__DIR__}/../README.md")
             |> String.split("\n")
             |> Enum.drop(2)
             |> Enum.join("\n")

  @type vpack :: binary | iodata

  @doc """
  Parses the the first _VelocyPack_ value from a binary or iodata.

  The options parameter is reserved for future use and not used at the moment.
  """
  @spec decode(vpack) :: {:ok, term} | {:ok, {term, vpack}} | {:error, any}
  def decode(vpack, opts \\ []) do
    __MODULE__.Decoder.parse(IO.iodata_to_binary(vpack), opts)
  end

  @doc """
  Parses the the first _VelocyPack_ value from a binary or iodata.

  Same as `decode/2` except it will unwrap the tuple and raise
  in case of errors.
  """
  @spec decode!(vpack) :: term | {term, vpack}
  def decode!(vpack, opts \\ []) do
    case decode(vpack, opts) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Generates a _VelocyPack_ value as a binary corresponding to `term`.

  The generation is controlled by the `Velocy.Encoder` protocol,
  please refer to the module to read more on how to define the protocol
  for custom data types.

  The options parameter is reserved for future use and not used at the moment.
  """
  @spec encode(term) :: {:ok, vpack} | {:error, any}
  def encode(term, opts \\ []) do
    case __MODULE__.Encode.encode(term, opts) do
      {:ok, vpack} -> {:ok, IO.iodata_to_binary(vpack)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates a _VelocyPack_ value as a binary corresponding to `term`.

  Same as `encode/2` except it will unwrap the tuple and raise
  in case of errors.
  """
  @spec encode!(term) :: vpack
  def encode!(term, opts \\ []) do
    case encode(term, opts) do
      {:ok, vpack} -> vpack
      {:error, reason} -> raise reason
    end
  end
end
