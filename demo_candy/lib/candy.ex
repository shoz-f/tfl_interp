defmodule Candy do
  @width  224
  @height 224

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/candy.tflite",
    url: "https://github.com/shoz-f/tinyML_livebook/releases/download/model/candy.tflite",
    inputs: [f32: {1,@height,@width,3}],
    outputs: [f32: {1,@height,@width,3}]

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
   
   #postprocess
   output
   |> CImg.from_binary(@width, @height, 1, 3, [{:range, {0.0, 255.0}}, :nchw])
   |> CImg.resize(img)
  end
end
