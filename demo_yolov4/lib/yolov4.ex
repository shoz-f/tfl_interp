defmodule YOLOv4 do
  @moduledoc """
  Original work:
    Pytorch-YOLOv4 - https://github.com/Tianxiaomo/pytorch-YOLOv4
  """

  @width  608
  @height 608

  @preproc CImg.builder()
            |> CImg.resize({@width, @height})
            |> CImg.to_binary([{:range, {0.0, 1.0}}, :nchw])

  alias TflInterp, as: NNInterp
  use NNInterp, label: "./model/coco.label",
    model: "./model/yolov4_1_3_608_608_static.tflite",
    url: "https://drive.google.com/uc?authuser=0&export=download&confirm=t&id=1z02aAUJ_phk3mom_w7J1fKbe9F_UM1HT",
    inputs: [f32: {1,3,@width,@height}],
    outputs: [f32: {1,22743,1,4}, f32: {1,22743,80}]

  def apply(img) do
    # preprocess
    input0 = CImg.run(@preproc, img)

    # prediction
    outputs = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()

    # postprocess
    boxes  = NNInterp.get_output_tensor(outputs, 0)
    scores = NNInterp.get_output_tensor(outputs, 1)

    PostDNN.non_max_suppression_multi_class(
      {22743, 80}, boxes, scores,
      boxrepr: :corner,
      label: "./model/coco.label"
    )
  end
end
