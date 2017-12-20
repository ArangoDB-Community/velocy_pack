defmodule VelocyPack.Codegen do
  @moduledoc false

  # This is basically a direct copy of the Codegen Module
  # from https://github.com/michalmuskala/antidote with some
  # small modifications.

  def jump_table(ranges, default) do
    ranges
    |> ranges_to_orddict()
    |> :array.from_orddict(default)
    |> :array.to_orddict()
  end

  defmacro bytecase(var, do: clauses) do
    {ranges, default, literals} = clauses_to_ranges(clauses, [])

    jump_table = jump_table(ranges, default)

    quote do
      case unquote(var) do
        unquote(jump_table_to_clauses(jump_table, literals))
      end
    end
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
      <<unquote(byte), unquote(rest)::bits>> when unquote(byte) === unquote(val) ->
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
      {{:.., _, [s, e]}, value} ->
        Enum.map(s..e, &{&1, value})
    end)
    |> :orddict.from_list()
  end
end