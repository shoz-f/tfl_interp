defmodule YoloX do
  @width  640
  @height 640

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/yolox_s.tflite",
    label: "./model/coco.label",
    url: "https://github.com/shoz-f/tinyML_livebook/releases/download/model/yolox_s.tflite",
    inputs: [f32: {1,3,@height,@width}],
    outputs: [f32: {1,8400,85}]

  def apply(img) do
    # preprocess
    input0 = CImg.builder(img)
      |> CImg.resize({@width, @height})
      |> CImg.to_binary([{:range, {0.0, 255.0}}, :nchw])

    # prediction
    output = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> Nx.from_binary(:f32) |> Nx.reshape({:auto, 85})
    
    # postprocess
    output = Nx.transpose(output)

    boxes  = extract_boxes(output)
    scores = extract_scores(output)

    TflInterp.non_max_suppression_multi_class(__MODULE__,
      Nx.shape(scores), Nx.to_binary(boxes), Nx.to_binary(scores)
    )
  end

  @grid PostDNN.meshgrid({@width, @height}, [8, 16, 32], [:transpose, :normalize])

  defp  extract_boxes(t) do
    # decode box center coordinate on {1.0, 1.0}
    center = t[0..1]
      |> Nx.multiply(@grid[2..3])  # * pitch(x,y)
      |> Nx.add(@grid[0..1])    # + grid(x,y)

    # decode box size
    size = t[2..3]
      |> Nx.exp()
      |> Nx.multiply(@grid[2..3]) # * pitch(x,y)

    Nx.concatenate([center, size]) |> Nx.transpose()
  end

  defp extract_scores(t) do
    Nx.multiply(t[4], t[5..-1//1])
    |> Nx.transpose()
  end
end
