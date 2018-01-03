defmodule VelocyPack.Codegen do
  @moduledoc false

  # Most of this code is basically a direct copy of the Codegen
  # Module from https://github.com/michalmuskala/jason with some
  # small modifications.

  import Bitwise

  defmacro power_of_2(exp) do
    result = 1 <<< exp
    quote do: unquote(result)
  end

  defmacro index_table(offsets, offset, 1), do:
    quote do: for i <- unquote(offsets), do: <<(i + unquote(offset))::unsigned-size(8)>>
  defmacro index_table(offsets, offset, 2), do:
    quote do: for i <- unquote(offsets), do: <<(i + unquote(offset))::unsigned-little-size(16)>>
  defmacro index_table(offsets, offset, 4), do:
    quote do: for i <- unquote(offsets), do: <<(i + unquote(offset))::unsigned-little-size(32)>>
  defmacro index_table(offsets, offset, 8), do:
    quote do: for i <- unquote(offsets), do: <<(i + unquote(offset))::unsigned-little-size(64)>>

  defmacro bytecase(var, do: clauses) do
    {ranges, default, literals} = clauses_to_ranges(clauses, [])

    jump_table = jump_table(ranges, default)

    quote do
      case unquote(var) do
        unquote(jump_table_to_clauses(jump_table, literals))
      end
    end
  end

  defp jump_table(ranges, default) do
    ranges
    |> ranges_to_orddict()
    |> :array.from_orddict(default)
    |> :array.to_orddict()
  end

  defp clauses_to_ranges([{:->, _, [[{:in, _, [byte, range]}, rest], action]} | tail], acc) do
    clauses_to_ranges(tail, [{range, {byte, rest, action}} | acc])
  end
  defp clauses_to_ranges([{:->, _, [[default, rest], action]} | tail], acc) do
    {Enum.reverse(acc), {default, rest, action}, literal_clauses(tail)}
  end

  defp literal_clauses(clauses) do
    Enum.map(clauses, fn {:->, _, [[literal], action]} ->
      {literal, action}
    end)
  end

  defp jump_table_to_clauses([{val, {{:_, _, _}, rest, action}} | tail], empty) do
    quote do
      <<unquote(val), unquote(rest)::bits>> ->
        unquote(action)
    end ++ jump_table_to_clauses(tail, empty)
  end
  defp jump_table_to_clauses([{val, {byte, rest, action}} | tail], empty) do
    quote do
      <<unquote(val), unquote(rest)::bits>> ->
        unquote(byte) = unquote(val)
        unquote(action)
    end ++ jump_table_to_clauses(tail, empty)
  end
  defp jump_table_to_clauses([], literals) do
    Enum.flat_map(literals, fn {pattern, action} ->
      quote do
        unquote(pattern) ->
          unquote(action)
      end
    end)
  end

  defmacro jump_table_case(var, rest, ranges, default) do
    clauses =
      ranges
      |> jump_table(default)
      |> Enum.flat_map(fn {byte_value, action} ->
        quote do
          <<unquote(byte_value), unquote(rest)::bits>> ->
            unquote(action)
        end
      end)

    clauses = clauses ++ quote(do: (<<>> -> empty_error(original, skip)))
    quote do
      case unquote(var) do
        unquote(clauses)
      end
    end
  end

  defp ranges_to_orddict(ranges) do
    ranges
    |> Enum.flat_map(fn
      {int, value} when is_integer(int) ->
        [{int, value}]
      {{:.., _, [s, e]}, value} when is_integer(s) and is_integer(e) ->
        Enum.map(s..e, &{&1, value})
    end)
    |> :orddict.from_list()
  end
end
