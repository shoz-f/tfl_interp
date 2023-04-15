defmodule HairSegmentation do
  @width  512
  @height 512

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/hair_segmentation.tflite",
    url: "https://storage.googleapis.com/mediapipe-assets/hair_segmentation.tflite",
    inputs: [f32: {1,@width,@height,4}],
    outputs: [f32: {1,@width,@height,2}]

  def apply(img) do
    # preprocess
    input0 = CImg.builder(img)
      |> CImg.resize({@width, @height})
      |> CImg.append(CImg.create(@width, @height, 1, 1, 0), :c)
      |> CImg.to_binary([{:range, {0.0, 1.0}}])

    # prediction
    output = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> Nx.from_binary(:f32) |> Nx.reshape({@height,@width,:auto})

    # postprocess
    [background, hair] = Enum.map(0..1, fn i ->
      Nx.slice_along_axis(output, i, 1, axis: 2) |> Nx.squeeze()
    end)
    
    {w,h,_,_} = CImg.shape(img)

    Nx.greater(hair, background)
    |> Nx.to_binary()
    |> CImg.from_binary(@width, @height, 1, 1, dtype: "<u1")
    |> CImg.resize({w, h})
  end
end
