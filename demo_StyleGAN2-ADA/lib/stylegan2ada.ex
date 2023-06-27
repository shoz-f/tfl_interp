defmodule StyleGAN2ADA.Mapping do
  alias TflInterp, as: NNInterp

  use NNInterp,
    model: "./model/afhqdog.mapping.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/afhqdog.mapping.tflite",
    inputs: [f32: {1,512}],
    outputs: [f32: {1,16.512}]

  def dlatants() do
    dlatants(for _ <- 1..512, into: "", do: <<:rand.normal()::little-float-32>>)
  end

  def dlatants(latants) do
    # preprocess
    input0 = latants

    # prediction
    output0 = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
    
    # postprocess
    Nx.from_binary(output0, :f32) |> Nx.reshape({16, 512})
  end
end

defmodule StyleGAN2ADA.Synthesis do
  @width  512
  @height 512

  alias TflInterp, as: NNInterp

  use NNInterp,
    model: "./model/afhqdog.synthesis.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/afhqdog.synthesis.tflite",
    inputs: [f32: {1,16,512}],
    outputs: [f32: {1,3,@height,@width}]

  def image(dlatants) do
    # preprocess
    input0 = Nx.to_binary(dlatants)

    # prediction
    output0 = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)

    # postprocess
    CImg.from_binary(output0, @width, @height, 1, 3, [{:range, {-1.0, 1.0}}, :nchw])
  end
end
