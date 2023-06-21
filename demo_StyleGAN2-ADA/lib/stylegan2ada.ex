defmodule StyleGAN2ADA do
  @width  512
  @height 512

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/afhqdog.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/afhqdog.tflite",
    inputs: [f32: {1,512}],
    outputs: [f32: {1,3,@height,@width}]

  def apply() do
    # preprocess
    input0 = for _ <- 1..512, into: "", do: <<:rand.normal()::little-float-32>>

    # prediction
    output0 = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)

    # postprocess
    CImg.from_binary(output0, @width, @height, 1, 3, [{:range, {-1.0, 1.0}}, :nchw])
  end
end
