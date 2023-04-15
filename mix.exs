defmodule TflInterp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_interp,
      version: "0.1.10",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      compilers: unless(check_env?("SKIP_MAKE_TFLINTERP"), do: [:cmake], else: []) ++ Mix.compilers(),
      description: description(),
      package: package(),
      deps: deps(),

      cmake: cmake(),
      
      # Docs
      # name: "tfl_interp",
      source_url: "https://github.com/shoz-f/tfl_interp.git",

      docs: docs()
    ]
  end

  defp check_env?(name), do:
    System.get_env(name, "NO") |> String.upcase() |> Kernel.in(["YES", "OK", "TRUE"])

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl, :inets]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 5.0"},
      {:castore, "~> 0.1.19"},
      {:progress_bar, "~> 2.0"},
      {:mix_cmake, "~> 0.1.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
  
  # Cmake configuration.
  defp cmake do
    [
      # Specify cmake build directory or pseudo-path {:local, :global}.
      #   :local(default) - "./_build/.cmake_build"
      #   :global - "~/.#{Cmake.app_name()}"
      #build_dir: :local,

      # Specify cmake source directory.(default: File.cwd!)
      #source_dir: File.cwd!,

      # Specify jobs parallel level.
      build_parallel_level: 4
    ]
    ++ case :os.type do
      {:win32, :nt} -> cmake_win32()
      _ -> []
    end
  end

  defp cmake_win32 do
    [
      # Specify generator name.
      # "cmake --help" shows you build-in generators list.
      #generator: "Visual Studio 16 2019",

      # Specify CPU architecture
      platform: "x64",

      # Visual C++ configuration
      build_config: "Release"
    ]
  end

  defp description() do
    "Tensorflow lite intepreter for Elixir."
  end

  defp package() do
    [
       name: "tfl_interp",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/shoz-f/tfl_interp.git"},
      files: ~w(lib mix.exs README* CHANGELOG* LICENSE* CMakeLists.txt msys2.* *.cmake src)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
#        "LICENSE",
        "CHANGELOG.md",

        #Examples
        "demo_mbert_qa/mbert_qa.livemd",
        "demo_movenet/MoveNet.livemd",
        "demo_yolov4/YOLOv4.livemd",
        "demo_ResNet18/Resnet18.livemd",
        "demo_hairsegmentation/HairSegmentation.livemd"
      ],
      groups_for_extras: [
        "Examples": Path.wildcard("demo_*/*.livemd")
      ],
#      source_ref: "v#{@version}",
#      source_url: @source_url,
#      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
