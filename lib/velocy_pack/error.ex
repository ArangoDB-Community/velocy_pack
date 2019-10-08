defmodule VelocyPack.Error do
  defexception [:dump, message: "velocy_pack error"]

  def exception(%MatchError{term: ""}) do
    %__MODULE__{message: "unexpected sequence", dump: nil}
  end

  def exception(%CaseClauseError{term: ""}) do
    %__MODULE__{message: "unexpected sequence", dump: nil}
  end

  def exception(%MatchError{term: bytes}) do
    %__MODULE__{message: "unexpected byte", dump: dump(bytes)}
  end

  def exception(%CaseClauseError{term: bytes}) do
    %__MODULE__{message: "unexpected byte", dump: dump(bytes)}
  end

  def exception(message), do: %__MODULE__{message: message}

  def message(%__MODULE__{message: message, dump: nil}), do: message

  def message(%__MODULE__{message: message, dump: ""}), do: message

  def message(%__MODULE__{message: message, dump: dump}), do: "#{message}: #{dump}"

  defp dump(bytes) when is_binary(bytes), do: inspect(bytes, base: :hex)
  defp dump(_bytes), do: "not a binary"
end
