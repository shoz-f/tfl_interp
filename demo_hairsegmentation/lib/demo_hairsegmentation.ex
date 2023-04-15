defmodule DemoHairSegmentation do
  def run(path) do
    img = CImg.load(path)

    mask = HairSegmentation.apply(img)

    CImg.paint_mask(img, mask, [{0, 255, 255}], 0.4)
    |> CImg.save("result.jpg")
  end
end
