defprotocol VelocyPack.Encoder do
  @moduledoc """
  Protocol controlling how a value is encoded to _VelocyPack_.
  """

  def encode(value, opts)
end

defimpl VelocyPack.Encoder, for: Atom do
  def encode(value, _opts) do
    VelocyPack.Encode.atom(value)
  end
end

defimpl VelocyPack.Encoder, for: Integer do
  def encode(value, _opts) do
    VelocyPack.Encode.integer(value)
  end
end

defimpl VelocyPack.Encoder, for: Float do
  def encode(value, _opts) do
    VelocyPack.Encode.float(value)
  end
end

defimpl VelocyPack.Encoder, for: BitString do
  def encode(value, _opts) when is_binary(value) do
    VelocyPack.Encode.string(value)
  end

  def encode(value, _) do
    raise Protocol.UndefinedError,
      protocol: @protocol,
      value: value,
      description: "cannot encode a bitstring to VelocyPack"
  end
end

defimpl VelocyPack.Encoder, for: List do
  def encode(value, opts) do
    VelocyPack.Encode.list(value, opts)
  end
end

defimpl VelocyPack.Encoder, for: Map do
  def encode(value, opts) do
    VelocyPack.Encode.map(value, opts)
  end
end
