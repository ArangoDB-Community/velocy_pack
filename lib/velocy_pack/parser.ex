defmodule VelocyPack.Parser do
  @moduledoc false

  # The implementation of this parser is heavily inspired by that of Antidote (https://github.com/michalmuskala/antidote)

  use Bitwise
  alias VelocyPack.Codegen
  import Codegen, only: [bytecase: 2]

  @spec parse(binary(), keyword()) :: {:ok, any()} | {:error, any()}
  def parse(data, _opts \\ []) when is_binary(data) do
    try do
      {value, <<>>} = value(data)
      {:ok, value}
    catch
      err ->
        {:error, err}
    end
  end

  @spec parse(binary(), keyword()) :: any() | no_return()
  def parse!(data, opts \\ []) do
    case parse(data, opts) do
      {:ok, value} -> value
      {:error, err} -> raise err
    end
  end

  @spec value(binary()) :: {any(), binary()}
  defp value(data) do
    bytecase data do
      _ in 0x01, rest -> {[], rest}

      type in 0x02..0x05, rest -> parse_array_without_index_table(type, rest)
      type in 0x06..0x09, rest -> parse_array_with_index_table(type, rest)

      _ in 0x0a, rest -> {%{}, rest}
      type in 0x0b..0x0e, rest -> parse_object(type, rest)

      # 0x0f..0x12 - unused
      _ in 0x13, rest -> parse_compact_array(rest)
      _ in 0x14, rest -> parse_compact_object(rest)

      # 0x15..0x16 - reserved
      _ in 0x17, rest -> {:illegal, rest}
      _ in 0x18, rest -> {nil, rest}
      _ in 0x19, rest -> {false, rest}
      _ in 0x1a, rest -> {true, rest}
      _ in 0x1b, rest -> parse_double(rest)
      _ in 0x1c, rest -> parse_date_time(rest)

      # 0x1d - external -> not supported
      _ in 0x1e, rest -> {:min_key, rest}
      _ in 0x1f, rest -> {:max_key, rest}

      type in 0x20..0x27, rest -> parse_int(type, rest)
      type in 0x28..0x2f, rest -> parse_uint(type, rest)
      type in 0x30..0x39, rest -> parse_small_int(type, rest)
      type in 0x3a..0x3f, rest -> parse_neg_small_int(type, rest)

      type in 0x40..0xbe, rest -> parse_short_string(type, rest)
      _ in 0xbf, rest -> parse_string(rest)

      type in 0xc0..0xc7, rest -> parse_binary(type, rest)

      # 0xc8..0xcf - BCD -> not supported
      # 0xd0..0xd7 - negative BCD -> not supported
      # 0xd8..0xef - reserved
      # 0xf0..0xff - custom types -> not supported

      type, _rest ->
        error({:unsupported_type, type})
      <<>> ->
        error(:unexpected_end)
    end
  end

  defp error(err), do: throw err

  @spec value_size(binary()) :: integer() | no_return()
  defp value_size(data) do
    bytecase data do
      _ in 0x01, _ -> 1
      type in 0x02..0x09, rest -> get_array_size(type, rest)
      _ in 0x0a, _ -> 1
      type in 0x0b..0x0e, rest -> get_object_size(type, rest)
      _ in 0x13..0x14, rest -> get_compact_size(rest)
      # 0x15..0x16 - reserved
      _ in 0x17..0x1c, _ -> 1
      # 0x1d - external -> not supported
      _ in 0x1e..0x1f, _ -> 1
      type in 0x20..0x27, _ -> type - 0x1f
      type in 0x28..0x2f, _ -> type - 0x27
      _ in 0x30..0x3f, _ -> 1
      type in 0x40..0xbe, _ -> type - 0x40
      _ in 0xbf, rest -> get_string_size(rest)
      type in 0xc0..0xc7, rest -> get_binary_size(type, rest)

      # 0xc8..0xcf - BCD -> not supported
      # 0xd0..0xd7 - negative BCD -> not supported
      # 0xd8..0xef - reserved
      # 0xf0..0xff - custom types -> not supported

      type, _rest ->
        error({:unsupported_type, type})
      <<>> ->
        error(:unexpected_end)
    end
  end

  @compile {:inline, parse_double: 1}
  @spec parse_double(binary()) :: {any(), binary()}
  defp parse_double(<<value::float-little-size(64), rest::binary>>),
    do: {value, rest}

  @compile {:inline, parse_date_time: 1}
  @spec parse_date_time(binary()) :: {any(), binary()}
  defp parse_date_time(<<value::integer-unsigned-little-size(64), rest::binary>>),
    do: {DateTime.from_unix(value, :milliseconds), rest}

  @compile {:inline, parse_int: 2}
  @spec parse_int(integer(), binary()) :: {any(), binary()}
  defp parse_int(type, data) do
    size = type - 0x1f
    <<value::integer-signed-little-unit(8)-size(size), rest::binary>> = data
    {value, rest}
  end

  @compile {:inline, parse_uint: 2}
  @spec parse_uint(integer(), binary()) :: {any(), binary()}
  defp parse_uint(type, data) do
    size = type - 0x27
    <<value::integer-unsigned-little-unit(8)-size(size), rest::binary>> = data
    {value, rest}
  end

  @compile {:inline, parse_small_int: 2}
  @spec parse_small_int(integer(), binary()) :: {any(), binary()}
  defp parse_small_int(type, rest),
    do: {type - 0x30, rest}

  @compile {:inline, parse_neg_small_int: 2}
  @spec parse_neg_small_int(integer(), binary()) :: {any(), binary()}
  defp parse_neg_small_int(type, rest),
    do: {type - 0x40, rest}

  @compile {:inline, parse_short_string: 2}
  @spec parse_short_string(integer(), binary()) :: {any(), binary()}
  defp parse_short_string(type, data) do
    length = type - 0x40
    parse_short_string_content(length, data)
  end

  @spec parse_short_string_content(integer(), binary()) :: {any(), binary()}
  defp parse_short_string_content(length, data) do
    <<value::binary-size(length), rest::binary>> = data
    {value, rest}
  end

  @spec parse_string( binary()) :: {any(), binary()}
  defp parse_string(data) do
    <<length::integer-unsigned-little-size(64), value::binary-size(length), rest::binary>> = data
    {value, rest}
  end

  @compile {:inline, parse_binary: 2}
  @spec parse_binary(integer(), binary()) :: {any(), binary()}
  defp parse_binary(type, data) do
    size = type - 0xbf
    parse_binary_content(size, data)
  end

  @spec parse_binary_content(integer(), binary()) :: {any(), binary()}
  defp parse_binary_content(size, data) do
    <<length::integer-unsigned-little-unit(8)-size(size), value::binary-size(length), rest::binary>> = data
    {value, rest}
  end

  @spec get_array_size(integer(), binary()) :: integer()
  defp get_array_size(type, data) do
    offset = if (type < 0x06), do: 0x02, else: 0x06
    size_bytes = 1 <<< (type - offset)
    <<size::integer-unsigned-little-unit(8)-size(size_bytes), _rest::binary>> = data
    size
  end

  @spec get_object_size(integer(), binary()) :: integer()
  defp get_object_size(type, data) do
    offset = if (type < 0x0e), do: 0x0b, else: 0x0e
    size_bytes = 1 <<< (type - offset)
    <<size::integer-unsigned-little-unit(8)-size(size_bytes), _rest::binary>> = data
    size
  end

  @spec get_binary_size(integer(), binary()) :: integer()
  defp get_binary_size(type, data) do
    size = type - 0xbf
    <<length::integer-unsigned-little-unit(8)-size(size), _rest::binary>> = data
    length
  end

  @spec get_compact_size(binary()) :: integer()
  defp get_compact_size(data) do
    {size, _} = parse_length(data, 0, 0, false)
    size
  end

  @spec get_string_size(binary()) :: integer()
  defp get_string_size(<<length::integer-unsigned-little-size(64), _::binary>>), do: length + 8 + 1

  @spec parse_array_without_index_table(integer(), binary()) :: {list(), binary()}
  defp parse_array_without_index_table(type, data) do
    size_bytes = 1 <<< (type - 0x02)
    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes), rest::binary>> = data
    elem_size = value_size(rest)
    length = div((total_size - size_bytes - 1), elem_size)
    parse_fixed_size_array_elements(length, elem_size, skip_zeros(rest))
  end

  @spec skip_zeros(binary()) :: binary()
  defp skip_zeros(<<0, rest::binary>>), do: skip_zeros(rest)
  defp skip_zeros(data), do: data

  @spec parse_fixed_size_array_elements(integer(), integer(), binary()) :: {list(), binary()}
  defp parse_fixed_size_array_elements(0, _, data), do: {[], data}
  defp parse_fixed_size_array_elements(length, elem_size, data) do
    <<elem::binary-unit(8)-size(elem_size), rest::binary>> = data
    {elem, <<>>} = value(elem)
    {list, rest} = parse_fixed_size_array_elements(length - 1, elem_size, rest)
    {[elem | list], rest}
  end

  @spec parse_array_with_index_table(integer(), binary()) :: {list(), binary()}
  defp parse_array_with_index_table(0x09, data) do
    <<total_size::integer-unsigned-little-size(64), rest::binary>> = data
    data_size = total_size - 1 - 8 - 8;
    <<data::binary-size(data_size), length::integer-unsigned-little-size(64), rest::binary>> = rest
    { parse_array_with_index_table_elements(length, 8, data), rest}
  end
  defp parse_array_with_index_table(type, data) do
    size_bytes = 1 <<< (type - 0x06)
    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes),
      length::integer-unsigned-little-unit(8)-size(size_bytes),
      rest::binary>> = data
    data_size = total_size - 1 - 2 * size_bytes
    <<data::binary-size(data_size), rest::binary>> = rest
    list = parse_array_with_index_table_elements(length, size_bytes, data)
    { list, rest }
  end

  @spec parse_array_with_index_table_elements(integer(), integer(), binary()) :: list()
  defp parse_array_with_index_table_elements(length, size_bytes, data) do
    index_table_size = if (length == 1), do: 0, else: length * size_bytes
    {list, <<_index_table::binary-size(index_table_size)>>} = parse_variable_size_array_elements(length, data)
    list
  end

  @spec parse_variable_size_array_elements(integer(), binary()) :: {list(), binary()}
  defp parse_variable_size_array_elements(length, data),
    do: parse_array_elements(length, data)

  # Yes, we totaly do this in a non-tail-recursive way.
  # Performance tests large arrays (~10000 entries) showed
  # that this is ~10% faster than a tail-recursive version.
  @spec parse_array_elements(integer(), binary()) :: {list(), binary()}
  defp parse_array_elements(0, data), do: {[], data}
  defp parse_array_elements(length, data) do
    {elem, rest} = value(data)
    {list, rest} = parse_array_elements(length - 1, rest)
    {[elem | list], rest}
  end

  @spec parse_compact_array(binary()) :: {list(), binary()}
  defp parse_compact_array(data) do
    {data, length, rest} = parse_compact_header(data)
    {list, <<>>} = parse_variable_size_array_elements(length, data)
    {list, rest}
  end

  @spec parse_object(integer(), binary()) :: {map(), binary()}
  defp parse_object(type, data) do
    size_bytes = 1 <<< (type - 0x0b)
    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes),
      length::integer-unsigned-little-unit(8)-size(size_bytes),
      rest::binary>> = data
    data_size = total_size - 1 - 2 * size_bytes
    <<data::binary-size(data_size), rest::binary>> = rest
    index_table_size = if (length == 1), do: 0, else: length * size_bytes
    {obj, <<_index_table::binary-size(index_table_size)>>} = parse_object_members(length, %{}, skip_zeros(data))
    {obj, rest}
  end

  @spec parse_compact_object(binary()) :: {map(), binary()}
  defp parse_compact_object(data) do
    {data, length, rest} = parse_compact_header(data)
    {obj, <<>>} = parse_object_members(length, %{}, data)
    {obj, rest}
  end

  @spec parse_object_members(integer(), map(), binary()) :: {map(), binary()}
  defp parse_object_members(0, obj, data), do: {obj, data}
  defp parse_object_members(length, obj, data) do
    {key, rest} = value(data)
    {value, rest} = value(rest)
    obj = Map.put(obj, key, value)
    parse_object_members(length - 1, obj, rest)
  end

  @spec parse_compact_header(binary()) :: {binary(), integer(), binary()}
  defp parse_compact_header(data) do
    {size, rest} = parse_length(data, 0, 0, false)
    data_size = size - (byte_size(data) - byte_size(rest)) - 1
    <<data::binary-size(data_size), rest::binary>> = rest
    {length, data} = parse_length(data, 0, 0, true)
    {data, length, rest}
  end

  @spec parse_length(binary(), integer(), integer(), boolean()) :: {integer(), binary()}
  defp parse_length(data, len, p, reverse) do
    {v, rest} =
      if reverse do
        size = byte_size(data) - 1
        <<rest::binary-size(size), v>> = data
        {v, rest}
      else
        <<v, rest::binary>> = data
        {v, rest}
      end
    len = len + ((v &&& 0x7f) <<< p)
    p = p + 7
    if ((v &&& 0x80) != 0) do
      parse_length(rest, len, p, reverse)
    else
      {len, rest}
    end
  end
end
