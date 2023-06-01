defmodule StyleGAN2ADA do
  @width  256
  @height 256

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/idol-face-2021-03.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/idol-face-2021-03.tflite",
    inputs: [f32: {1,512}],
    outputs: [u8: {1,@height,@width,3}]

  def apply() do
    # preprocess
    input0 = for _ <- 1..512, into: "", do: <<:rand.normal()::little-float-32>>

    # prediction
    output0 = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)

    # postprocess
    CImg.from_binary(output0, @width, @height, 1, 3, dtype: "<u1")
  end
end
