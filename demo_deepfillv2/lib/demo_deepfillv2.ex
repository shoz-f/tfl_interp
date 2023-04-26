defmodule DemoDeepFillV2 do
  def run(path_img, path_mask) do
    img  = CImg.load(path_img)
    mask = CImg.load(path_mask)

    DeepFillV2.apply(img, mask)
    |> CImg.save("result.jpg")
  end
end
