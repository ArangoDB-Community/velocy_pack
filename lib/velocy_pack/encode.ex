defmodule VelocyPack.Encode do

  def encode(value, opts \\ []) do
    try do
      {:ok, value(value, opts)}
    catch
      err -> {:error, err}
    end
  end

  @doc """
  Equivalent to calling the `VelocyPack.Encoder.encode/2` protocol function.
  """
  #def value(value, _) do
  #  value(value)
  #end

  @doc false
  # We use this directly in the helpers and deriving for extra speed
  def value(value, _) when is_atom(value) do
    encode_atom(value)
  end

  def value(value, opts) when is_binary(value) do
    encode_string(value, opts)
  end

  def value(value, opts) when is_integer(value) do
    integer(value, opts)
  end

  def value(value, opts) when is_float(value) do
    float(value, opts)
  end

  def value(value, opts) when is_list(value) do
    list(value, opts)
  end

  def value(value, opts) when is_map(value) do
    map(value, opts)
  end

  # TODO: Dates, Structs

  # Atom

  def atom(atom, _), do: encode_atom(atom)

  defp encode_atom(nil), do: [<<0x18>>]
  defp encode_atom(false), do: [<<0x19>>]
  defp encode_atom(true), do: [<<0x1a>>]
  defp encode_atom(:min_key), do: [<<0x1e>>]
  defp encode_atom(:max_key), do: [<<0x1f>>]
  defp encode_atom(:illegal), do: [<<0x17>>]
  defp encode_atom(value) do
    value
    |> Atom.to_string()
    |> encode_string([])
  end

  # Integer

  import VelocyPack.Codegen#, only: [power_of_2: 1, index_table: 3]

  def integer(value, _), do: encode_integer(value)

  defp encode_integer(value) when value in 0..9, do: [<<0x30 + value>>]
  defp encode_integer(value) when value in -6..-1, do: [<<0x40 + value>>]

  # negative integers
  defp encode_integer(value) when value < -power_of_2(63),
    do: raise "Cannot encode integers less than #{-power_of_2(63)}."
  for i <- 8..1, do:
    defp encode_integer(value) when value < -power_of_2(unquote((i - 1) * 8 - 1)),
      do: [<<unquote(0x1f + i), value::little-unsigned-size(unquote(i * 8))>>]

  # positive integers
  for i <- 1..8, do:
    defp encode_integer(value) when value < power_of_2(unquote(i * 8)),
      do: [<<unquote(0x27 + i), value::little-unsigned-size(unquote(i * 8))>>]
  defp encode_integer(_),
    do: raise "Cannot encode integers greater than #{power_of_2(64) - 1}."

  # Float

  def float(value, _), do: [<<0x1b, value::float-little-size(64)>>]

  # Strings

  def string(value, opts), do: encode_string(value, opts)

  def encode_string("", _), do: [0x40]
  def encode_string(value, _) when byte_size(value) <= 126 do
    [<<(byte_size(value) + 0x40), value::binary>>]
  end
  def encode_string(value, _) when is_binary(value) do
    length = byte_size(value)
    <<0xbf, length::integer-unsigned-little-size(64), value::binary>>
  end

  # Lists

  def list(value, opts), do: encode_list(value, opts)

  defp encode_list([], _), do: [<<0x01>>]
  defp encode_list(value, opts) do
    # Use a singe pass to calculate the offsets, the total size, the number of elements
    # and whether all elements have the same size.
    {iolist, {offsets, total_size, count, last_size}} = value |> Enum.map_reduce({[], 0, 0, nil},
      fn (v, {offsets, total_size, count, last_size}) ->
        v = value(v, opts) |> IO.iodata_to_binary
        size = byte_size(v)
        last_size = cond do
          last_size == false -> false
          last_size == size -> size
          last_size == nil -> size
          true -> false
        end
        {v, {[total_size | offsets], total_size + size, count + 1, last_size}}
      end)
    offsets = :lists.reverse(offsets)

    cond do
      is_integer(last_size) ->
        # all elements have the same size -> create an array without index table
        encode_list_without_index_table(iolist, total_size)

      true ->
        encode_list_with_index_table(iolist, count, offsets, total_size)
    end
    |> IO.iodata_to_binary
  end

  for i <- 1..4 do
    defp encode_list_without_index_table(iolist, total_size) when total_size < power_of_2(unquote(i * 8)) do
      total_size = total_size + 1 + power_of_2(unquote(i - 1))
      [<<unquote(0x01 + i), total_size::integer-unsigned-little-unit(8)-size(power_of_2(unquote(i - 1)))>> | iolist]
    end
  end

  defp encode_list_with_index_table(iolist, count, offsets, total_size) do
    cond do
      count < power_of_2(8) and total_size + count + 3 < power_of_2(8) ->
        total_size = total_size + count + 3
        [<<0x06, total_size::unsigned-size(8), count::unsigned-size(8)>>, iolist, index_table(offsets, 3, 1)]

      count < power_of_2(16) and total_size + count * 2 + 5 < power_of_2(16) ->
        total_size = total_size + count * 2 + 5
        [<<0x07, total_size::unsigned-little-size(16), count::unsigned-little-size(16)>>, iolist, index_table(offsets, 5, 2)]

      count < power_of_2(32) and total_size + count * 4 + 9 < power_of_2(32) ->
        total_size = total_size + count * 4 + 9
        [<<0x08, total_size::unsigned-little-size(32), count::unsigned-little-size(32)>>, iolist, index_table(offsets, 9, 4)]

      true ->
        total_size = total_size + count * 8 + 9
        [<<0x09, total_size::unsigned-little-size(64), count::unsigned-little-size(64)>>, iolist, index_table(offsets, 9, 8)]
    end
  end

  # TODO - compact array

  # Maps

  def map(value, opts), do: encode_map(value, opts)

  defp encode_map(value, _) when value === %{} , do: [<<0x0a>>]
  defp encode_map(value, opts) do
    {iolist, {offsets, total_size, count}} =
      value
      |> Enum.map(fn {k, v} -> {as_key(k), v} end)
      |> Enum.sort()
      |> Enum.map_reduce({[], 0, 0},
        fn ({k, v}, {offsets, total_size, count}) ->
          res = [string(k, opts), value(v, opts)] |> IO.iodata_to_binary
          size = byte_size(res)
          {res, {[total_size | offsets], total_size + size, count + 1}}
        end)
    offsets = :lists.reverse(offsets)
    encode_map_with_index_table(iolist, count, offsets, total_size)
    |> IO.iodata_to_binary
  end

  defp encode_map_with_index_table(iolist, count, offsets, total_size) do
    cond do
      count == 1 and total_size + 3 < power_of_2(8) ->
        total_size = total_size + 3
        [<<0x0b, total_size::unsigned-size(8), 1::unsigned-size(8)>> | iolist]

      count < power_of_2(8) and total_size + count + 3 < power_of_2(8) ->
        total_size = total_size + count + 3
        [<<0x0b, total_size::unsigned-size(8), count::unsigned-size(8)>>, iolist, index_table(offsets, 3, 1)]

      count < power_of_2(16) and total_size + count * 2 + 5 < power_of_2(16) ->
        total_size = total_size + count * 2 + 5
        [<<0x0c, total_size::unsigned-little-size(16), count::unsigned-little-size(16)>>, iolist, index_table(offsets, 5, 2)]

      count < power_of_2(32) and total_size + count * 4 + 9 < power_of_2(32) ->
        total_size = total_size + count * 4 + 9
        [<<0x0d, total_size::unsigned-little-size(32), count::unsigned-little-size(32)>>, iolist, index_table(offsets, 9, 4)]

      true ->
        total_size = total_size + count * 8 + 9
        [<<0x0e, total_size::unsigned-little-size(64)>>, iolist, index_table(offsets, 9, 8), <<count::unsigned-little-size(64)>>]
    end
  end

  # TODO - compact objects

  defp as_key(value) when is_atom(value), do: Atom.to_string(value)
  defp as_key(value) when is_binary(value), do: value
  defp as_key(value), do: raise "Invalid key '#{inspect value}' - keys have to be atoms or strings."
end
