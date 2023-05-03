defmodule DeepFillV2 do
  @width  680
  @height 512

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/deepfillv2.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/deepfillv2.tflite",
    inputs: [f32: {1,@height,2*@width,3}],
    outputs: [u8: {1,@height,@width,3}]

  def apply(img, mask) do
    # preprocess
    input0 = CImg.builder(img)
      |> CImg.append(mask, :x)
      |> CImg.resize({2*@width, @height})
      |> CImg.to_binary(range: {0.0, 255.0})

    # prediction
    {w, h, _, _} = CImg.shape(img)

    session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> CImg.from_binary(@width, @height, 1, 3, [{:dtype, "<u1"}, :bgr])
      |> CImg.resize({w, h})
  end
end
