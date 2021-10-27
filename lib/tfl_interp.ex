defmodule TflInterp do
  @timeout 300000

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

  @doc "Get the propaty of the tflite interpreter"
  def info(mod) do
    cmd = 0
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
  end
  
  @doc "Stop the tflite interpreter"
  def stop(mod) do
    GenServer.stop(mod)
  end

  @doc "put a flat binary to the input tensor on the interpreter"
  def set_input_tensor(mod, index, bin) do
    cmd = 1
    case GenServer.call(mod, <<cmd::8, index::8, bin::binary>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
    mod
  end

  @doc "invoke prediction"
  def invoke(mod) do
    cmd = 2
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
    mod
  end

  @doc "get the flat binary from the output tensor on the interpreter"
  def get_output_tensor(mod, index) do
    cmd = 3
    case GenServer.call(mod, <<cmd::8, index::8>>, @timeout) do
      {:ok, result} -> result
      any -> any
    end
  end

  @doc "execute post processing: nms"
  def non_max_suppression_multi_class(mod, num_boxes, num_class, boxes, scores, iou_threshold \\ 0.5, score_threshold \\ 0.25, sigma \\ 0.0) do
    cmd = 4
    case GenServer.call(mod, <<cmd::8, num_boxes::little-integer-32, num_class::little-integer-32, iou_threshold::little-float-32, score_threshold::little-float-32, sigma::little-float-32>> <> boxes <> scores, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
  end
end
