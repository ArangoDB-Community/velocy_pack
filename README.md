# VelocyPack

An Elixir parser and generator for [VelocyPack](https://github.com/arangodb/velocypack/blob/master/VelocyPack.md) v1.

The implementation is heavily inspired by [Jason](https://github.com/michalmuskala/jason) and
borrows some code (specifically the Codegen module).

## Examples

```elixir
iex> {:ok, vpack} = VelocyPack.encode(10.2312514)
{:ok, <<27, 245, 78, 96, 149, 102, 118, 36, 64>>}
iex> VelocyPack.decode(vpack)
{:ok, 10.2312514}

iex> vpack = VelocyPack.encode!(%{a: "a", b: %{bool: true, float: 10.2312514}})
<<11, 37, 2, 65, 97, 65, 97, 65, 98, 11, 26, 2, 68, 98, 111, 111, 108, 26, 69, 102, 108, 111, 97, 116, 27, 245, 78, 96, 149, 102, 118, 36, 64, 3, 9, 3, 7>>
iex> VelocyPack.decode!(vpack)
%{"a" => "a", "b" => %{"bool" => true, "float" => 10.2312514}}

iex> VelocyPack.decode(<<11>>)
{:error, %VelocyPack.Error{message: "unexpected sequence", dump: nil}}

iex> VelocyPack.decode!(<<11>>)
** (VelocyPack.Error) unexpected sequence

iex> VelocyPack.decode(<<11, 823891328731>>)
{:error, %VelocyPack.Error{message: "unexpected byte", dump: "<<0xDB>>"}}

iex> VelocyPack.decode!(<<11, 823891328731>>)
** (VelocyPack.Error) unexpected byte: <<0xDB>>
```