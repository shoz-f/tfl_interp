defmodule Midas do
  @moduledoc """
  # Monocular Depth Estimation: MiDaS v2.1
  
  ## Original work
    Intelligent Systems Lab Org:
    "Towards Robust Monocular Depth Estimation: Mixing Datasets for Zero-shot Cross-dataset Transfer"

    * https://arxiv.org/abs/1907.01341v3
    * https://github.com/isl-org/MiDaS

  Thanks a lot!!!
  """

  @width  256
  @height 256

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/model_opt.tflite",
    url: "https://github.com/isl-org/MiDaS/releases/download/v2_1/model_opt.tflite",
    inputs: [f32: {1,@height,@width,3}],
    outputs: [f32: {1,@height,@width,3}]

  def apply(img) do
    # preprocess
    input0 = CImg.builder(img)
      |> CImg.resize({@width, @height})
      |> CImg.to_binary(range: {-1.0, 1.0})

    # prediction
    output = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> Nx.from_binary(:f32) |> Nx.reshape({@height, @width})

    # postprocess
    [min, max] = 
      [Nx.window_min(output, {@height, @width}), Nx.window_max(output, {@height, @width})]
      |> Enum.map(&Nx.squeeze/1)
      |> Enum.map(&Nx.to_number/1)

    {w, h, _, _} = CImg.shape(img)

    Nx.subtract(output, min)
    |> Nx.divide(max-min)
    |> Nx.to_binary()
    |> CImg.from_binary(@width, @height, 1, 1)
    |> CImg.resize({w, h})
  end
end
