defmodule DemoMidas do
  def run(path) do
    img  = CImg.load(path)

    Midas.apply(img)
    |> CImg.color_mapping(:jet)
    |> CImg.save("result.jpg")
  end
end
