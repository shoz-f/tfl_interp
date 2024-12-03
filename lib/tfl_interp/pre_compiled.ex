defmodule TflInterp.PreCompiled do
  alias TflInterp.URL

  @url %{
    "tflite-cpu-windows-x86_64" =>
      {"tfl_interp.exe", "https://github.com/shoz-f/tfl_interp/releases/download/0.1.16/tfl_interp-cpu-windows-x86_64.zip"},
    "tflite-cpu-linux-x86_64" =>
      {"tfl_interp", "https://github.com/shoz-f/tfl_interp/releases/download/0.1.16/tfl_interp-cpu-linux-x86_64.zip"},
  }

  @os_default (case :os.type() do
    {:win32, :nt}   -> %{name: {"windows", "x86_64"}, ext: ".exe"}
    {:unix, :linux} -> %{name: {"linux",   "x86_64"}, ext: ""}
    x -> IO.inspect(x, label: "[Error] Unknown host os")
  end)


  def using_precompiled?(),
    do: System.get_env("NNCOMPILED", "NO") |> String.upcase() |> Kernel.in(["YES", "OK", "TRUE"])

  def download(name, force \\ false) do
    # complement target name.
    spec = unless name, do: [], else: String.split(name, "-")
    size = Enum.count(spec)

    target = spec
      |> append_if(size < 1, "tflite")
      |> append_if(size < 2, "cpu")
      |> append_if(size < 3, elem(@os_default.name, 0))
      |> append_if(size < 4, elem(@os_default.name, 1))
      |> Enum.join("-")

    # download *interp
    {exe, url} = Map.get(@url, target)
    folder     = Application.app_dir(:tfl_interp, "priv")
    executable = Path.join(folder, exe)

    if force || !File.exists?(executable) do
      {:ok, _} = URL.download(url, folder)
    end

    executable
  end

  defp append_if(a, true,  x), do: List.insert_at(a, -1, x)
  defp append_if(a, false, _), do: a
end
