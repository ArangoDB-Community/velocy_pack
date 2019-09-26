defmodule VelocyPack.Encode do
  def encode(value, opts \\ []) do
    try do
      {v, _size} = value(value, parse_opts(opts))
      {:ok, v}
    catch
      err -> {:error, err}
    end
  end

  defp parse_opts(opts) do
    {
      Keyword.get(opts, :compact_arrays, false),
      Keyword.get(opts, :compact_objects, false)
    }
  end

  @doc false
  def value(value, _) when is_atom(value) do
    encode_atom(value)
  end

  def value(value, _) when is_binary(value) do
    encode_string(value)
  end

  def value(value, _) when is_integer(value) do
    encode_integer(value)
  end

  def value(value, _) when is_float(value) do
    float(value)
  end

  def value(value, opts) when is_list(value) do
    encode_list(value, opts)
  end

  def value(value, opts) when is_map(value) do
    encode_map(value, opts)
  end

  def value(value, opts) do
    VelocyPack.Encoder.encode(value, opts)
  end

  use VelocyPack.Codegen

  # TODO: Dates, Structs

  # Atom

  def atom(atom), do: encode_atom(atom)

  defp encode_atom(nil), do: {[<<0x18>>], 1}
  defp encode_atom(false), do: {[<<0x19>>], 1}
  defp encode_atom(true), do: {[<<0x1A>>], 1}
  defp encode_atom(:min_key), do: {[<<0x1E>>], 1}
  defp encode_atom(:max_key), do: {[<<0x1F>>], 1}
  defp encode_atom(:illegal), do: {[<<0x17>>], 1}

  defp encode_atom(value) do
    value
    |> Atom.to_string()
    |> encode_string()
  end

  # Integer

  def integer(value), do: encode_integer(value)

  defp encode_integer(value) when value in 0..9, do: {[<<0x30 + value>>], 1}
  defp encode_integer(value) when value in -6..-1, do: {[<<0x40 + value>>], 1}

  # negative integers
  defp encode_integer(value) when value < -power_of_2(63),
    do: raise("Cannot encode integers less than #{-power_of_2(63)}.")

  for i <- 8..1,
      do:
        defp(encode_integer(value) when value < -power_of_2(unquote((i - 1) * 8 - 1)),
          do:
            {[<<unquote(0x1F + i), value::little-unsigned-size(unquote(i * 8))>>], unquote(i) + 1}
        )

  # positive integers
  for i <- 1..8,
      do:
        defp(encode_integer(value) when value < power_of_2(unquote(i * 8)),
          do:
            {[<<unquote(0x27 + i), value::little-unsigned-size(unquote(i * 8))>>], unquote(i) + 1}
        )

  defp encode_integer(_) do
    raise "Cannot encode integers greater than #{power_of_2(64) - 1}."
  end

  # Float

  def float(value), do: {[<<0x1B, value::float-little-size(64)>>], 9}

  # Strings

  def string(value), do: encode_string(value)

  defp encode_string(""), do: {[<<0x40>>], 1}

  defp encode_string(value) when byte_size(value) <= 126 do
    {[<<byte_size(value) + 0x40, value::binary>>], byte_size(value) + 1}
  end

  defp encode_string(value) when is_binary(value) do
    length = byte_size(value)
    {[<<0xBF, length::integer-unsigned-little-size(64), value::binary>>], length + 9}
  end

  # Lists

  def list(value, opts), do: encode_list(value, opts)

  defp encode_list([], _), do: {[<<0x01>>], 1}
  # compact array
  defp encode_list(value, {true, _} = opts) do
    {iodata, total_size, count} =
      value
      |> Enum.reduce(
        {[], 0, 0},
        fn v, {acc, total_size, count} ->
          {v, size} = value(v, opts)
          {[v | acc], total_size + size, count + 1}
        end
      )

    iodata = :lists.reverse(iodata)

    iodata = if count >= 1000, do: IO.iodata_to_binary(iodata), else: iodata
    encode_compact_data(<<0x13>>, iodata, total_size, count)
  end

  defp encode_list([head | tail], opts) do
    # Use a singe pass to calculate the offsets, the total size, the number of elements
    # and whether all elements have the same size.
    {head, head_size} = value(head, opts)

    {iodata, offsets, total_size, count, equal_sizes} =
      tail
      |> Enum.reduce(
        {[head], [0], head_size, 1, true},
        fn v, {acc, offsets, total_size, count, equal_sizes} ->
          {v, size} = value(v, opts)
          equal_sizes = equal_sizes && size == head_size
          {[v | acc], [total_size | offsets], total_size + size, count + 1, equal_sizes}
        end
      )

    iodata = :lists.reverse(iodata)

    # NOTE: we do not reverse the offsets list, because this is done
    #       implicitly when we generate the iodata for the index table.

    # Tests showed that for large lists it is significantly faster
    # to immediately convert the data to binary.
    iodata = if count >= 1000, do: IO.iodata_to_binary(iodata), else: iodata

    cond do
      equal_sizes ->
        # all elements have the same size -> create an array without index table
        encode_list_without_index_table(iodata, total_size)

      true ->
        encode_list_with_index_table(iodata, count, offsets, total_size)
    end
  end

  for i <- 1..4 do
    defp encode_list_without_index_table(iodata, total_size)
         when total_size < power_of_2(unquote(i * 8)) do
      total_size = total_size + 1 + power_of_2(unquote(i - 1))

      {[
         <<unquote(0x01 + i),
           total_size::integer-unsigned-little-unit(8)-size(power_of_2(unquote(i - 1)))>>
         | iodata
       ], total_size}
    end
  end

  defp encode_list_with_index_table(iodata, count, offsets, total_size) do
    cond do
      count < power_of_2(8) and total_size + count + 3 < power_of_2(8) ->
        total_size = total_size + count + 3

        {[
           <<0x06, total_size::unsigned-size(8), count::unsigned-size(8)>>,
           iodata,
           index_table(offsets, 3, 1)
         ], total_size}

      count < power_of_2(16) and total_size + count * 2 + 5 < power_of_2(16) ->
        total_size = total_size + count * 2 + 5

        {[
           <<0x07, total_size::unsigned-little-size(16), count::unsigned-little-size(16)>>,
           iodata,
           index_table(offsets, 5, 2)
         ], total_size}

      count < power_of_2(32) and total_size + count * 4 + 9 < power_of_2(32) ->
        total_size = total_size + count * 4 + 9

        {[
           <<0x08, total_size::unsigned-little-size(32), count::unsigned-little-size(32)>>,
           iodata,
           index_table(offsets, 9, 4)
         ], total_size}

      true ->
        total_size = total_size + count * 8 + 17

        {[
           <<0x09, total_size::unsigned-little-size(64), count::unsigned-little-size(64)>>,
           iodata,
           index_table(offsets, 17, 8)
         ], total_size}
    end
  end

  # Maps

  def map(value, opts), do: encode_map(value, opts)

  defp encode_map(value, _) when value === %{}, do: {[<<0x0A>>], 1}
  # compact object
  defp encode_map(value, {_, true} = opts) do
    {iodata, total_size, count} =
      value
      |> Enum.reduce(
        {[], 0, 0},
        fn {k, v}, {acc, total_size, count} ->
          {key, key_size} = encode_string(as_key(k))
          {val, val_size} = value(v, opts)
          size = key_size + val_size
          {[val, key | acc], total_size + size, count + 1}
        end
      )

    iodata = :lists.reverse(iodata)

    iodata = if count >= 1000, do: IO.iodata_to_binary(iodata), else: iodata
    encode_compact_data(<<0x14>>, iodata, total_size, count)
  end

  defp encode_map(value, opts) do
    {iodata, offsets, total_size, count} =
      value
      |> Enum.map(fn {k, v} -> {as_key(k), v} end)
      |> Enum.sort()
      |> Enum.reduce(
        {[], [], 0, 0},
        fn {k, v}, {acc, offsets, total_size, count} ->
          {key, key_size} = encode_string(k)
          {val, val_size} = value(v, opts)
          size = key_size + val_size
          {[val, key | acc], [total_size | offsets], total_size + size, count + 1}
        end
      )

    iodata = :lists.reverse(iodata)

    # NOTE: we do not reverse the offsets list, because this is done
    #       implicitly when we generate the iodata for the index table.

    iodata = if count >= 1000, do: IO.iodata_to_binary(iodata), else: iodata
    encode_map_with_index_table(iodata, count, offsets, total_size)
  end

  defp encode_map_with_index_table(iodata, count, offsets, total_size) do
    cond do
      count == 1 and total_size + 3 < power_of_2(8) ->
        total_size = total_size + count + 3

        {[<<0x0B, total_size::unsigned-size(8), 1::unsigned-size(8)>> | iodata] ++ [3],
         total_size}

      count < power_of_2(8) and total_size + count + 3 < power_of_2(8) ->
        total_size = total_size + count + 3

        {[
           <<0x0B, total_size::unsigned-size(8), count::unsigned-size(8)>>,
           iodata,
           index_table(offsets, 3, 1)
         ], total_size}

      count < power_of_2(16) and total_size + count * 2 + 5 < power_of_2(16) ->
        total_size = total_size + count * 2 + 5

        {[
           <<0x0C, total_size::unsigned-little-size(16), count::unsigned-little-size(16)>>,
           iodata,
           index_table(offsets, 5, 2)
         ], total_size}

      count < power_of_2(32) and total_size + count * 4 + 9 < power_of_2(32) ->
        total_size = total_size + count * 4 + 9

        {[
           <<0x0D, total_size::unsigned-little-size(32), count::unsigned-little-size(32)>>,
           iodata,
           index_table(offsets, 9, 4)
         ], total_size}

      true ->
        total_size = total_size + count * 8 + 17

        {[
           <<0x0E, total_size::unsigned-little-size(64)>>,
           iodata,
           index_table(offsets, 9, 8),
           <<count::unsigned-little-size(64)>>
         ], total_size}
    end
  end

  defp as_key(value) when is_atom(value), do: Atom.to_string(value)
  defp as_key(value) when is_binary(value), do: value

  defp as_key(value),
    do: raise("Invalid key '#{inspect(value)}' - keys have to be atoms or strings.")

  use Bitwise

  defp encode_compact_data(type, data, total_size, count) do
    encoded_count = compact_integer(count, true)
    total_size = total_size + 1 + Enum.count(encoded_count)
    {encoded_total_size, total_size} = compact_size(total_size)
    {[type, encoded_total_size, data | encoded_count], total_size}
  end

  defp compact_size(size) do
    bytes = calc_compact_bytes(size)
    final_size = size + bytes

    final_size =
      if bytes == calc_compact_bytes(final_size) do
        final_size
      else
        # Due to the number of bytes required for the size information itself
        # we need an additional byte to encode the final total size.
        final_size + 1
      end

    {compact_integer(final_size, false), final_size}
  end

  defp compact_integer(value, reverse) do
    v = compact_integer(value)
    if reverse, do: :lists.reverse(v), else: v
  end

  defp compact_integer(value) when value < power_of_2(7) do
    [<<value::unsigned-size(8)>>]
  end

  defp compact_integer(value) do
    v = (value &&& 0x7F) ||| 1 <<< 7
    value = value >>> 7
    [<<v::unsigned-size(8)>> | compact_integer(value)]
  end

  defp calc_compact_bytes(value), do: calc_compact_bytes(value, 0)
  defp calc_compact_bytes(0, count), do: count
  defp calc_compact_bytes(value, count), do: calc_compact_bytes(value >>> 7, count + 1)
end
