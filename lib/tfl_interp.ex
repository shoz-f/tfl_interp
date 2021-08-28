defmodule TflInterp do
  @timeout 300000

  defmacro __using__(opts) do
    quote generated: true, location: :keep do
      use GenServer

      def start_link(opts \\ [model: "test/yolov3-416-dr.tflite", label: "test/coco.label"]) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(opts) do
        executable = Application.app_dir(:tfl_interp, "priv/tfl_interp")
        tfl_model  = Keyword.get(opts, :model)
        tfl_label  = Keyword.get(opts, :label)
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
    end
  end

  def info(mod) do
    cmd = 0
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
  end

  def set_input_tensor(mod, index, bin) do
    cmd = 1
    case GenServer.call(mod, <<cmd::8, index::8, bin::binary>>, @timeout) do
      {:ok, result} ->  Poison.decode(result)
      any -> any
    end
  end

  def invoke(mod) do
    cmd = 2
    case GenServer.call(mod, <<cmd::8>>, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
  end

  def get_output_tensor(mod, index) do
    cmd = 3
    case GenServer.call(mod, <<cmd::8, index::8>>, @timeout) do
      {:ok, result} -> result
      any -> any
    end
  end

  def non_max_suppression_multi_class(mod, idx_boxes, idx_scores, iou_threshold, score_threshold, sigma) do
    cmd = 4
    case GenServer.call(mod, <<cmd::8, idx_boxes::8, idx_scores::8, iou_threshold::little-float-32, score_threshold::little-float-32, sigma::little-float-32>>, @timeout) do
      {:ok, result} -> Poison.decode(result)
      any -> any
    end
  end
end
