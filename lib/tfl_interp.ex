defmodule TflInterp do
  @timeout 300000

  @moduledoc """
  Tensorflow lite intepreter for Elixir.
  Deep Learning inference framework for embedded devices.

  ## Installation
  This module is designed for Poncho-style. Therefore, it cannot be installed
  by adding this module to your project's dependency list. Follow the steps
  below to install.

  Download `tfl_interp` to a directory of your choice. I recommend that you put
  it in the same hierarchy as your Deep Learning project directory.

  ```shell
  $ cd parent-of-your-project
  $ git clone https://github.com/shoz-f/tfl_interp.git
  ```

  Then you need to download the file set of Google Tensorflow and build
  `tfl_intep` executable (Port extended called by Elixir) into ./priv.

  Don't worry, `mix_cmake` utility will help you.

  ```shell
  $ cd tfl_interp
  $ mix deps.get
  $ mix cmake --config

  ;-) It takes a few minutes to download and build Tensorflow.
  ```

  Now you are ready. The figure below shows the directory structure of tfl_interp.

  ```
  +- your-project
  |
  +- tfl_interp
       +- _build
       |    +- .cmake_build --- Tensorflow is downloaded here
       +- deps
       +- lib
       +- priv
       |    +- tfl_interp   --- Elixir Port extended
       +- src/
       +- test/
       +- CMakeLists.txt    --- Cmake configuration script
       +- mix.exs           --- includes parameter for mix-cmake task
       +- msys2.patch       --- Patch script for MSYS2/MinGW64
  ```

  ## Basic Usage
  To use TflInterp in your project, you add the path to `tfl_interp` above to
  the `mix.exs`:

  ```elixir:mix.exs
  def deps do
    [
      {:tfl_interp, path: "../tfl_interp"},
    ]
  end
  ```

  Then you put the trained model of Tensolflow lite in ./priv.

  ```shell
  $ cp your-trained-model.tflite ./priv
  ```

  The remaining task is to create a module that will interface with your Deep
  Learning model. The module will probably have pre-processing and post-processing
  in addition to inference processing, as in the code example below. TflInterp
  provides only inference processing.

  You put `use TflInterp` at the beginning of your module, specify the model path
  in optional arguments. The inference section involves inputing data to the
  model - `TflInterp.set_input_tensor/3`, executing it - `TflInterp.invoke/1`,
  and extracting the results - `TflInterp.get_output_tensor/2`.

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

  @doc """
  Get the propaty of the tflite model.

  ## Parameters
  
    * mod - modules' names
  """
  def info(mod) do
    cmd = 0
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
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
  """
  def set_input_tensor(mod, index, bin) do
    cmd = 1
    case GenServer.call(mod, <<cmd::8, index::8, bin::binary>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
    mod
  end

  @doc """
  Invoke prediction.

  ## Parameters
  
    * mod - modules' names
  """
  def invoke(mod) do
    cmd = 2
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
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
  def get_output_tensor(mod, index) do
    cmd = 3
    case GenServer.call(mod, <<cmd::8, index::8>>, @timeout) do
      {:ok, result} -> result
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
    cmd = 4
    case GenServer.call(mod, <<cmd::8, num_boxes::little-integer-32, num_class::little-integer-32, iou_threshold::little-float-32, score_threshold::little-float-32, sigma::little-float-32>> <> boxes <> scores, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
  end
end
