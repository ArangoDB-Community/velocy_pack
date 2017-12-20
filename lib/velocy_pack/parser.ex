defmodule VelocyPack.Parser do
  @moduledoc false

  # The implementation of this parser is heavily inspired by that of Antidote (https://github.com/michalmuskala/antidote)

  alias VelocyPack.Codegen
  import Codegen, only: [bytecase: 2]

  def parse(data, _opts \\ []) when is_binary(data) do
    try do
      {value, <<>>} = value(data)
      {:ok, value}
    catch
      err ->
        {:error, err}      
    end
  end

  def parse!(data, opts \\ []) do
    case parse(data, opts) do
      {:ok, value} -> value
      {:error, err} -> raise err
    end
  end

  defp value(data) do
    bytecase data do
      _ in 0x01, rest -> {[], rest}

      _ in 0x0a, rest -> {%{}, rest}

      # 0x15..0x16 - reserved
      _ in 0x17, rest -> {:illegal, rest}
      _ in 0x18, rest -> {nil, rest}
      _ in 0x19, rest -> {false, rest}
      _ in 0x1a, rest -> {true, rest}
      _ in 0x1b, rest -> parse_double(rest)
      _ in 0x1c, rest -> parse_date_time(rest)

      # 0x1d = external -> not supported
      _ in 0x1e, rest -> {:min_key, rest}
      _ in 0x1f, rest -> {:max_key, rest}
      
      type in 0x20..0x27, rest -> parse_int(type, rest)
      type in 0x28..0x2f, rest -> parse_uint(type, rest)

      type, _rest ->
        throw {:unsupported_type, type}
    end
  end

  @compile {:inline, parse_double: 1}
  defp parse_double(<<value::float-little-size(64), rest::binary>>),
    do: {value, rest}

  @compile {:inline, parse_date_time: 1}
  defp parse_date_time(<<value::integer-unsigned-little-size(64), rest::binary>>),
    do: {DateTime.from_unix(value, :milliseconds), rest}

  @compile {:inline, parse_int: 2}
  defp parse_int(type, data) do
    size = type - 0x1f
    <<value::integer-signed-little-unit(8)-size(size), rest::binary>> = data
    {value, rest}
  end

  @compile {:inline, parse_uint: 2}
  defp parse_uint(type, data) do
    size = type - 0x27
    <<value::integer-unsigned-little-unit(8)-size(size), rest::binary>> = data
    {value, rest}
  end

end