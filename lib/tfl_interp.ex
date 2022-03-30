defmodule TflInterp do
  @moduledoc """
  Tensorflow lite intepreter for Elixir.
  Deep Learning inference framework for embedded devices.

  ## Design policy (Features)
  TflInterp is designed based on the following policy.

  1. Provide only the Deep Learning inference. It aims to the poor-resource devices such as IOT and mobile.
  2. Easy to understand. The inference part, excluding pre/post-processing, can be written in a few lines.
  3. Use trained models from major Deep Learning frameworks that are easy to obtain.
  4. Multiple inference models can be used from a single application.
  5. There are few dependent modules. It does not have image processing or matrix calculation functions.
  6. TflInterp does not block the erlang/elixir process scheduler. It runs as an OS process outside of elixir.
  7. The back-end inference engine can be easily replaced. It's easy to keep up with the latest Deep Learninig technology.

  And I'm trying to make TflInterp easy to install.

  ### short or concise history
  The development of Tflinterp started in 2020 Nov. The original idea was to use Nerves to create an AI remote controlled car.
  In the first version, I implemented Yolo3, but the design strongly depended on the model, which made it difficult to use in other applications.
  Reflecting on that mistake, I redesigned Tflinterp according to the above design guidelines.

  ## Installation
  Since 0.1.3, the installation method of this module has changed.
  You may need to remove previously installed TflInterp before installing new version.

  There are two installation methods. You can choose either one according to your purpose.

  1. Like any other elixir module, add TflInterp to the dependency list in the mix.exs.

  ```
  def deps do
    [
      ...
      {:tfl_interp, github: "shoz-f/tfl_interp", branch: "nerves"}
    ]
  end
  ```

  2. Download TflInterp to a directory in advance, and add that path to the dependency list in mix.exs.

  ```
  # download TflInterp in advance.
  $ cd /home/{your home}/workdir
  $ git clone -b nerves https://github.com/shoz-f/tfl_interp.git
  ```

  ```
  def deps do
    [
      ...
      {:tfl_interp, path: "/home/{your home}/workdir/tfl_interp"}
    ]
  end
  ```

  Then you run the following commands in your application project.

  For native application:

  ```
  $ mix deps.get
  $ mix compile
  ```

  For Nerves application:

  ```
  $ export MIX_TARGET=rpi3  # <- specify target device tag
  $ mix deps.get
  $ mix firmware
  ```

  It takes a long time to finish the build. Because it will download the required files - Tensorflow sources,
  ARM toolchain [^1], etc - at the first build time.
  Method 1 saves the downloaded files under "{your app}/deps/tfl_interp". On the other hand,
  method 2 saves them under "/home/{your home}/workdir/tfl_interp".
  If you want to reuse the downloaded files in other applications, we recommend Method 2.

  In either method 1 or 2, the external modules required for Tensorflow lite are stored under
  "{your app}/_build/{target}/.cmake_build" according to the cmakelists.txt that comes with Tensorflow.

   [^1] Unfortunately, the ARM toolchain that comes with Nerves can not build Tensorflow lite. We need to get the toolchain recommended by the Tensorflow project.

  After installation, you will have the directory tree like these:

  Method 1

  ```
  work_dir
    +- your-app
         +- _build/
         |    +- dev/
         |         +- .cmake_build/ --- CMakeCash.txt and external modules that Tensorflowlite depends on.
         |         |                    The cmake build outputs are stored here also.
         |         +- lib/
         |         |    +- tfl_interp
         |         |         +- ebin/
         |         |         +- priv
         |         |              +- tfl_interp --- executable: tensorflow interpreter.
         |         :
         |
         +- deps/
         |    + tfl_interp
         |    |   +- 3rd_party/ --- Tensorflow sources, etc.
         |    |   +- lib/ --- TflInterp module.
         |    |   +- src/ --- tfl_interp C++ sources.
         |    |   +- test/
         |    |   +- toolchain/ --- ARM toolchains for Nerves.
         |    |   +- CMakeLists.txt --- CMake configuration for for building tfl_interp.
         |    |   +- mix.exs
         |    :
         |
         +- lib/
         +- test/
         +- mix.exs
  ```

  Method 2

  ```
  work_dir
    +- your-app
    |    +- _build/
    |    |    +- dev/
    |    |         +- .cmake_build/ --- CMakeCash.txt and external modules that Tensorflowlite depends on.
    |    |         |                    The cmake build outputs are stored here also.
    |    |         +- lib/
    |    |         |    +- tfl_interp
    |    |         |         +- ebin/
    |    |         |         +- priv
    |    |         |              +- tfl_interp --- executable: tensorflow interpreter.
    |    |         :
    |    |
    |    +- deps/
    |    +- lib/
    |    +- test/
    |    +- mix.exs
    |
    +- tfl_interp
         +- 3rd_party/ --- Tensorflow sources, etc.
         +- lib/ --- TflInterp module.
         +- src/ --- tfl_interp C++ sources.
         +- test/
         +- toolchain/ --- ARM toolchains for Nerves.
         +- CMakeLists.txt --- CMake configuration for for building tfl_interp.
         +- mix.exs
  ```

  ## Basic Usage
  You get the trained tflite model and save it in a directory that your application can read.
  "your-app/priv" may be good choice.
  
  ```
  $ cp your-trained-model.tflite ./priv
  ```
  
  Next, you will create a module that interfaces with the deep learning model. 
  The module will need pre-processing and post-processing in addition to inference
  processing, as in the example following. TflInterp provides inference processing
  only.
  
  You put `use TflInterp` at the beginning of your module, specify the model path as an optional argument. In the inference
  section, you will put data input to the model (`TflInterp.set_input_tensor/3`), inference execution (`TflInterp.invoke/1`),
  and inference result retrieval (`TflInterp.get_output_tensor/2`).

  ```elixr:your_model.ex
  defmodule YourApp.YourModel do
    use TflInterp, model: "priv/your-trained-model.tflite"

    def predict(data) do
      # preprocess
      #  to convert the data to be inferred to the input format of the model.
      input_bin = convert-float32-binaries(data)

      # inference
      #  typical I/O data for Tensorflow lite models is a serialized 32-bit float tensor.
      output_bin =
        __MODULE__
        |> TflInterp.set_input_tensor(0, input_bin)
        |> TflInterp.invoke()
        |> TflInterp.get_output_tensor(0)

      # postprocess
      #  add your post-processing here.
      #  you may need to reshape output_bin to tensor at first.
      tensor = output_bin
        |> Nx.from_binary({:f, 32})
        |> Nx.reshape({size-x, size-y, :auto})

      * your-postprocessing *
      ...
    end
  end
  ```
  """

  @timeout 300000
  @padding 0

  defmacro __using__(opts) do
    quote generated: true, location: :keep do
      use GenServer

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(opts) do
        executable = Application.app_dir(:tfl_interp, "priv/tfl_interp")
        opts = Keyword.merge(unquote(opts), opts)
        tfl_model  = Keyword.get(opts, :model)
        tfl_label  = Keyword.get(opts, :label, "none")
        tfl_opts   = Keyword.get(opts, :opts, "")

        port = Port.open({:spawn_executable, executable}, [
          {:args, String.split(tfl_opts) ++ [tfl_model, tfl_label]},
          {:packet, 4},
          :binary
        ])

        {:ok, %{port: port}}
      end
      
      def session() do
        %TflInterp{module: __MODULE__}
      end

      def handle_call(cmd_line, _from, state) do
        Port.command(state.port, cmd_line)
        response = receive do
          {_, {:data, <<result::binary>>}} -> {:ok, result}
        after
          Keyword.get(unquote(opts), :timeout, 300000) -> {:timeout}
        end
        {:reply, response, state}
      end

      def terminate(_reason, state) do
        Port.close(state.port)
      end
    end
  end

  defstruct module: nil, input: [], output: []

  @doc """
  Get the propaty of the tflite model.

  ## Parameters

    * mod - modules' names
  """
  def info(mod) do
    cmd = 0
    case GenServer.call(mod, <<cmd::little-integer-32>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
  end

  @doc """
  Stop the tflite interpreter.

  ## Parameters

    * mod - modules' names
  """
  def stop(mod) do
    GenServer.stop(mod)
  end

  @doc """
  Put a flat binary to the input tensor on the interpreter.

  ## Parameters

    * mod   - modules' names
    * index - index of input tensor in the model
    * bin   - input data - flat binary, cf. serialized tensor
    * opts  - data conversion
  """
  def set_input_tensor(mod, index, bin, opts \\ [])

  def set_input_tensor(mod, index, bin, opts) when is_atom(mod) do
    cmd = 1
    case GenServer.call(mod, <<cmd::little-integer-32>> <> input_tensor(index, bin, opts), @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
    mod
  end
  
  def set_input_tensor(%TflInterp{input: input}=session, index, bin, opts) do                                                                       
    %TflInterp{session | input: [input_tensor(index, bin, opts) | input]}
  end
  
  defp input_tensor(index, bin, opts) do
    dtype = case Keyword.get(opts, :dtype, "none") do
      "none" -> 0
      "<f4"  -> 1
      "<f2"  -> 2
    end
    {lo, hi} = Keyword.get(opts, :range, {0.0, 1.0})
    
    size = 16 + byte_size(bin)
    
    <<size::little-integer-32, index::little-integer-32, dtype::little-integer-32, lo::little-float-32, hi::little-float-32, bin::binary>>
  end

  @doc """
  Invoke prediction.

  ## Parameters

    * mod - modules' names
  """
  def invoke(mod) when is_atom(mod) do
    cmd = 2
    case GenServer.call(mod, <<cmd::little-integer-32>>, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
    mod
  end

  @doc """
  Get the flat binary from the output tensor on the interpreter"

  ## Parameters

    * mod   - modules' names
    * index - index of output tensor in the model
  """
  def get_output_tensor(mod, index) when is_atom(mod) do
    cmd = 3
    case GenServer.call(mod, <<cmd::little-integer-32, index::little-integer-32>>, @timeout) do
      {:ok, result} -> result
      any -> any
    end
  end
  
  def get_output_tensor(%TflInterp{output: output}, index) do
    Enum.at(output, index)
  end

  @doc """
  """
  def run(%TflInterp{module: mod, input: input}=session) do
    cmd   = 4
    count = Enum.count(input)
    data  = Enum.reduce(input, <<>>, fn x,acc -> acc <> x end)
    case GenServer.call(mod, <<cmd::little-integer-32, count::little-integer-32>> <> data, @timeout) do
      {:ok, <<count::little-integer-32, results::binary>>} ->
      	  if count > 0 do
      	  	  %TflInterp{session | output: for <<size::little-integer-32, tensor::binary-size(size) <- results>> do tensor end}
      	  else
      	  	  "error: %{count}"
      	  end
      any -> any
    end
  end

  @doc """
  Execute post processing: nms.

  ## Parameters

    * mod             - modules' names
    * num_boxes       - number of candidate boxes
    * num_class       - number of category class
    * boxes           - binaries, serialized boxes tensor[`num_boxes`][4]; dtype: float32
    * scores          - binaries, serialized score tensor[`num_boxes`][`num_class`]; dtype: float32
    * iou_threshold   - IOU threshold
    * score_threshold - score cutoff threshold
    * sigma           - soft IOU parameter
  """

  def non_max_suppression_multi_class(mod, {num_boxes, num_class}, boxes, scores, iou_threshold \\ 0.5, score_threshold \\ 0.25, sigma \\ 0.0) do
    cmd = 5
    case GenServer.call(mod, <<cmd::little-integer-32, @padding::8*3, num_boxes::little-integer-32, num_class::little-integer-32, iou_threshold::little-float-32, score_threshold::little-float-32, sigma::little-float-32>> <> boxes <> scores, @timeout) do
      {:ok, nil} -> :notfind
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
  end
end
