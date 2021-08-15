defmodule Mix.Tasks.Cmake do
  alias Mix.Tasks.Cmake
  
  defmodule Config do
    use Mix.Task

    def run(argv) do
      cmake_config = Cmake.get_config()

      with {:ok, opts, dirs, cmake_opts} = Cmake.Getopt.parse(argv, strict: [verbose: :boolean])
      do
        [build_dir, source_dir] = case dirs do
          [build, source] -> [build, source]
          [build]         -> [build, cmake_config[:source_dir]]
          []              -> [cmake_config[:build_dir], cmake_config[:source_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()
        cmake_env = if Keyword.has_key?(cmake_config, :generator),
                      do: Map.put(cmake_env, "CMAKE_GENERATOR", cmake_config[:generator]),
                      else: cmake_env

        config(build_dir, source_dir, cmake_opts, cmake_env)
      end
    end

    def config(build_dir, source_dir, opts \\ [], env \\ %{}) do
      # convert dir name to absolute path
      build_path  = Cmake.build_path(build_dir)
      source_path = Cmake.source_path(source_dir)

      # make build directory
      File.mkdir_p(build_path)

      # construct cmake args
      opts = if build_dir == :share,
        do:   ["-UCMAKE_HOME_DIRECTORY", "-UCONFU_DEPENDENCIES_SOURCE_DIR" | opts], # add options to remove some cache entries
        else: opts

      # invoke cmake
      Cmake.cmake(build_path, opts ++ [source_path], env)

      build_path
    end
  end

  defmodule Build do
    use Mix.Task

    def run(argv) do
      cmake_config = Cmake.get_config()

      with {:ok, opts, dirs, cmake_opts} = Cmake.Getopt.parse(argv, strict: [verbose: :boolean])
      do
        [build_dir] = case dirs do
          [build]         -> [build]
          []              -> [cmake_config[:build_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()

        build(build_dir, cmake_opts, cmake_env)
      end
    end
    
    def build(build_dir, opts \\ [], env \\ %{}) do
      # convert dir name to absolute path
      build_path  = Cmake.build_path(build_dir)

      # invoke cmake
      Cmake.cmake(build_path, ["--build", "."] ++ opts, env)
    end
  end
  
  defmodule Install do
    use Mix.Task
    
    def run(argv) do
      cmake_config = Cmake.get_config()

      with {:ok, opts, dirs, cmake_opts} = Cmake.Getopt.parse(argv, strict: [verbose: :boolean])
      do
        [build_dir] = case dirs do
          [build]         -> [build]
          []              -> [cmake_config[:build_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()

        install(build_dir, cmake_opts, cmake_env)
      end
    end
    
    def install(build_dir, opts \\ [], env \\ %{}) do
      # convert dir name to absolute path
      build_path  = Cmake.build_path(build_dir)

      # invoke cmake
      Cmake.cmake(build_path, ["--install", "."] ++ opts, env)
    end
  end

  def cmake(build_path, args, env \\ %{}) do
    opts = [cd: build_path, env: env, into: IO.stream(:stdio, :line), stderr_to_stdout: true]

    IO.inspect([args: args, opts: opts])
    {%IO.Stream{}, status} = System.cmd("cmake", args, opts)
    status
  end

  def build_path(:private) do
    Mix.Project.build_path()
    |> Path.join("cmake")
  end

  def build_path(:share) do
    app_name =
      Mix.Project.config[:app]
      |> Atom.to_string()

    System.user_home
    |> Path.absname()
    |> Path.join(".#{app_name}")
  end

  def build_path(dir), do: Path.expand(dir)
  
  def source_path(dir), do: Path.expand(dir)

  def get_config() do
    Keyword.get(Mix.Project.config(), :cmake, [])
    |> Keyword.put_new(:build_dir, :priv)
    |> Keyword.put_new(:source_dir, File.cwd!)
  end

  # Returns a map of default environment variables
  # Defauts may be overwritten.
  def default_env() do
    root_dir = :code.root_dir()
    erl_interface_dir = Path.join(root_dir, "usr")
    erts_dir = Path.join(root_dir, "erts-#{:erlang.system_info(:version)}")
    erts_include_dir = Path.join(erts_dir, "include")
    erl_ei_lib_dir = Path.join(erl_interface_dir, "lib")
    erl_ei_include_dir = Path.join(erl_interface_dir, "include")

    %{
      # Don't use Mix.target/0 here for backwards compatability
      "MIX_TARGET" => env("MIX_TARGET", "host"),
      "MIX_ENV" => to_string(Mix.env()),
      "MIX_BUILD_PATH" => Mix.Project.build_path(),
      "MIX_APP_PATH" => Mix.Project.app_path(),
      "MIX_COMPILE_PATH" => Mix.Project.compile_path(),
      "MIX_CONSOLIDATION_PATH" => Mix.Project.consolidation_path(),
      "MIX_DEPS_PATH" => Mix.Project.deps_path(),
      "MIX_MANIFEST_PATH" => Mix.Project.manifest_path(),

      # Rebar naming
      "ERL_EI_LIBDIR" => env("ERL_EI_LIBDIR", erl_ei_lib_dir),
      "ERL_EI_INCLUDE_DIR" => env("ERL_EI_INCLUDE_DIR", erl_ei_include_dir),

      # erlang.mk naming
      "ERTS_INCLUDE_DIR" => env("ERTS_INCLUDE_DIR", erts_include_dir),
      "ERL_INTERFACE_LIB_DIR" => env("ERL_INTERFACE_LIB_DIR", erl_ei_lib_dir),
      "ERL_INTERFACE_INCLUDE_DIR" => env("ERL_INTERFACE_INCLUDE_DIR", erl_ei_include_dir)
    }
  end

  defp env(var, default) do
    System.get_env(var) || default
  end
end
