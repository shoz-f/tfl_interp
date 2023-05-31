defmodule TflInterp.PreCompiled do
  alias TflInterp.URL

  @url %{
    "tflite-cpu-windows-x86_64" =>
      "https://github.com/shoz-f/tfl_interp/releases/download/0.1.11/tfl_interp-cpu-windows-x86_64.exe",
    "tflite-cpu-linux-x86_64" =>
      "https://github.com/shoz-f/tfl_interp/releases/download/0.1.11/tfl_interp-cpu-linux-x86_64",
  }
  
  @os_default (case :os.type() do
    {:win32, :nt}   -> %{name: {"windows", "x86_64"}, ext: ".exe"}
    {:unix, :linue} -> %{name: {"linux",   "x86_64"}, ext: ""}
    x -> IO.inspect(x, label: "[Error] Unknown host os")
  end)
  

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
    url        = Map.get(@url, target)
    path       = Application.app_dir(:tfl_interp, "priv")
    executable = Path.join(path, Path.basename(url))

    if force || !File.exists?(executable) do
      URL.download(url, path)
      File.chmod(executable, 0o755)
    end

    executable
  end

  defp append_if(a, true,  x), do: List.insert_at(a, -1, x)
  defp append_if(a, false, _), do: a
end
