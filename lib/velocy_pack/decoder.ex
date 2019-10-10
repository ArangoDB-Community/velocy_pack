defmodule VelocyPack.Decoder do
  @moduledoc false

  # The implementation of this decoder is heavily inspired by that of Jason (https://github.com/michalmuskala/jason)

  use Bitwise
  alias VelocyPack.{Codegen, Error}
  import Codegen, only: [bytecase: 2]

  @spec parse(binary(), keyword()) :: {:ok, any()} | {:error, any()}
  def parse(data, _opts \\ []) when is_binary(data) do
    try do
      case value(data) do
        {value, <<>>} ->
          {:ok, value}

        {value, tail} ->
          {:ok, {value, tail}}
      end
    rescue
      e in MatchError ->
        {:error, Error.exception(e)}

      e in CaseClauseError ->
        {:error, Error.exception(e)}
    catch
      error ->
        {:error, error}
    end
  end

  @spec value(binary()) :: {any(), binary()}
  defp value(data) do
    bytecase data do
      _ in 0x01, rest ->
        {[], rest}

      type in 0x02..0x05, rest ->
        parse_array_without_index_table(type, rest)

      type in 0x06..0x09, rest ->
        parse_array_with_index_table(type, rest)

      _ in 0x0A, rest ->
        {%{}, rest}

      type in 0x0B..0x0E, rest ->
        parse_object(type, rest)

      # TODO: 0x0f..0x12 - objects with unsorted index table
      _ in 0x13, rest ->
        parse_compact_array(rest)

      _ in 0x14, rest ->
        parse_compact_object(rest)

      # 0x15..0x16 - reserved
      _ in 0x17, rest ->
        {:illegal, rest}

      _ in 0x18, rest ->
        {nil, rest}

      _ in 0x19, rest ->
        {false, rest}

      _ in 0x1A, rest ->
        {true, rest}

      _ in 0x1B, rest ->
        parse_double(rest)

      _ in 0x1C, rest ->
        parse_date_time(rest)

      # 0x1d - external -> not supported
      _ in 0x1E, rest ->
        {:min_key, rest}

      _ in 0x1F, rest ->
        {:max_key, rest}

      type in 0x20..0x27, rest ->
        parse_int(type, rest)

      type in 0x28..0x2F, rest ->
        parse_uint(type, rest)

      type in 0x30..0x39, rest ->
        parse_small_int(type, rest)

      type in 0x3A..0x3F, rest ->
        parse_neg_small_int(type, rest)

      _ in 0x40, rest ->
        {"", rest}

      type in 0x41..0xBE, rest ->
        parse_short_string(type, rest)

      _ in 0xBF, rest ->
        parse_string(rest)

      type in 0xC0..0xC7, rest ->
        parse_binary(type, rest)

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

  defp error(err), do: throw(err)

  @compile {:inline, parse_double: 1}
  @spec parse_double(binary()) :: {any(), binary()}
  defp parse_double(<<value::float-little-size(64), rest::binary>>),
    do: {value, rest}

  @compile {:inline, parse_date_time: 1}
  @spec parse_date_time(binary()) :: {any(), binary()}
  defp parse_date_time(<<value::integer-unsigned-little-size(64), rest::binary>>),
    do: {DateTime.from_unix!(value, :millisecond), rest}

  @compile {:inline, parse_int: 2}
  @spec parse_int(integer(), binary()) :: {any(), binary()}
  defp parse_int(type, data) do
    size = type - 0x1F
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

  @spec parse_string(binary()) :: {any(), binary()}
  defp parse_string(
         <<length::integer-unsigned-little-size(64), value::binary-size(length), rest::binary>>
       ) do
    {value, rest}
  end

  @compile {:inline, parse_binary: 2}
  @spec parse_binary(integer(), binary()) :: {any(), binary()}
  defp parse_binary(type, data) do
    size = type - 0xBF
    parse_binary_content(size, data)
  end

  @spec parse_binary_content(integer(), binary()) :: {any(), binary()}
  defp parse_binary_content(size, data) do
    <<length::integer-unsigned-little-unit(8)-size(size), value::binary-size(length),
      rest::binary>> = data

    {value, rest}
  end

  @spec parse_array_without_index_table(integer(), binary()) :: {list(), binary()}
  defp parse_array_without_index_table(type, data) do
    size_bytes = 1 <<< (type - 0x02)
    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes), rest::binary>> = data
    data_size = byte_size(rest)
    rest = skip_zeros(rest)
    zeros = data_size - byte_size(rest)
    data_size = total_size - size_bytes - 1 - zeros
    <<data::binary-size(data_size), rest::binary>> = rest
    list = parse_array_elements(data)
    # TODO - optionally validate length of list
    {list, rest}
  end

  @spec parse_array_with_index_table(integer(), binary()) :: {list(), binary()}
  defp parse_array_with_index_table(
         0x09,
         <<total_size::integer-unsigned-little-size(64), rest::binary>>
       ) do
    data_size = total_size - 1 - 8 - 8

    <<data::binary-size(data_size), length::integer-unsigned-little-size(64), rest::binary>> =
      rest

    index_size = length * 8
    data_size = data_size - index_size
    <<data::binary-size(data_size), _index::binary-size(index_size)>> = data

    list = parse_array_elements(data)
    # TODO - optionally validate length of list
    {list, rest}
  end

  defp parse_array_with_index_table(type, data) do
    size_bytes = 1 <<< (type - 0x06)

    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes),
      length::integer-unsigned-little-unit(8)-size(size_bytes), rest::binary>> = data

    index_size = size_bytes * length
    data_size = byte_size(rest)
    rest = skip_zeros(rest)
    zeros = data_size - byte_size(rest)

    data_size = total_size - 1 - 2 * size_bytes - zeros - index_size
    <<data::binary-size(data_size), _index::binary-size(index_size), rest::binary>> = rest
    list = parse_array_elements(data)
    # TODO - optionally validate length of list
    {list, rest}
  end

  @spec parse_compact_array(binary()) :: {list(), binary()}
  defp parse_compact_array(data) do
    {data, _length, rest} = parse_compact_header(data)
    list = parse_array_elements(data)
    # TODO - optionally validate length of list
    {list, rest}
  end


  # Yes, we totaly do this in a non-tail-recursive way.
  # Performance tests for large arrays (~10000 entries) showed
  # that this is ~10% faster than a tail-recursive version.
  # TODO - rerun performance tests
  @spec parse_array_elements(binary()) :: list()
  defp parse_array_elements(<<>>), do: []

  defp parse_array_elements(data) do
    {elem, rest} = value(data)
    [elem | parse_array_elements(rest)]
  end

  @spec parse_object(integer(), binary()) :: {map(), binary()}
  defp parse_object(type, data) do
    size_bytes = 1 <<< (type - 0x0B)

    <<total_size::integer-unsigned-little-unit(8)-size(size_bytes),
      length::integer-unsigned-little-unit(8)-size(size_bytes), rest::binary>> = data

    data_size = total_size - 1 - 2 * size_bytes
    <<data::binary-size(data_size), rest::binary>> = rest
    index_table_size = length * size_bytes

    {obj, <<_index_table::binary-size(index_table_size)>>} =
      parse_object_members(length, %{}, skip_zeros(data))

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

  @spec skip_zeros(binary()) :: binary()
  defp skip_zeros(<<0, rest::binary>>), do: skip_zeros(rest)
  defp skip_zeros(data), do: data

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

    len = len + ((v &&& 0x7F) <<< p)
    p = p + 7

    if (v &&& 0x80) != 0 do
      parse_length(rest, len, p, reverse)
    else
      {len, rest}
    end
  end
end
