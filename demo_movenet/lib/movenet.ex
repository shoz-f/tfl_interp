defmodule Movenet do

  @width  192
  @height 192

  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/lite-model_movenet_singlepose_lightning_tflite_int8_4.tflite",
    inputs: [u8: {1,@height,@width,3}],
    outputs: [f32: {1,1,17,3}]

  def apply(img) do
    # preprocess
    input0 = CImg.builder(img)
      |> CImg.resize({@width, @height}, :ul, 0)
      |> CImg.to_binary(dtype: "<u1")
    
    # prediction
    output0 = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> Nx.from_binary(:f32) |> Nx.reshape({17, 3})
    
    # postprocess
    {img_width, img_height, _, _} = CImg.shape(img)

    {:ok, to_bones(output0, {img_width, img_height})}
  end

  @bones [
    { 0,  1, {0,255,0}},
    { 0,  2, {0,255,0}},
    { 1,  3, {0,255,0}},
    { 2,  4, {0,255,0}},
    { 0,  5, {0,255,0}},
    { 0,  6, {0,255,0}},
    { 5,  7, {0,255,0}},
    { 7,  9, {0,255,0}},
    { 6,  8, {0,255,0}},
    { 8, 10, {0,255,0}},
    { 5,  6, {0,255,0}},
    { 5, 11, {0,255,0}},
    { 6, 12, {0,255,0}},
    {11, 12, {0,255,0}},
    {11, 13, {0,255,0}},
    {13, 15, {0,255,0}},
    {12, 14, {0,255,0}},
    {14, 16, {0,255,0}},
  ]
  
  def to_bones(t, {w, h}, threshold \\ 0.11) do
    {scale_x, scale_y} = if w > h, do: {1.0, w/h}, else: {h/w, 1.0}

    Enum.flat_map(@bones, fn {p1, p2, color} ->
      [y1,x1,score1] = Nx.to_flat_list(t[p1])
      [y2,x2,score2] = Nx.to_flat_list(t[p2])

      if (score1 > threshold) && (score2 > threshold) do
        [{x1*scale_x, y1*scale_y, x2*scale_x, y2*scale_y, color}]
      else
        []
      end
    end)
  end
end
