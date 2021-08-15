defmodule Mix.Tasks.Cmake.Getopt do
  def parse(argv, config \\ []) when is_list(argv) and is_list(config) do
    do_parse(argv, config, [], [])
  end

  defp do_parse([], _config, opts, args) do
    {:ok, opts, Enum.reverse(args), []}
  end

  defp do_parse(argv, config, opts, args) do
    case next(argv, config) do
      {:second, rest} ->  # start of 2nd args
        {:ok, opts, Enum.reverse(args), rest}
      {:ok, option, value, rest} ->
        do_parse(rest, config, [{option, value}|Keyword.delete(opts, option)], args)
      {:invalid, key, value, rest} ->
        {:invalid, key, value}
      {:undefined, key, _value, rest} ->
        {:undefined, key}
      {:error, [<<":",atom::binary>>|rest]} -> # atom formed
        do_parse(rest, config, opts, [String.to_atom(atom)|args])
      {:error, [arg|rest]} ->
        do_parse(rest, config, opts, [arg|args])
    end
  end

  def next(argv, opts \\ [])
  def next(["++"|rest], _opts), do: {:second, rest}
  def next(["--"|rest], _opts), do: {:second, rest}
  defdelegate next(argv, opts), to: OptionParser
end
