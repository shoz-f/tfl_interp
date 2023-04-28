defmodule DemoCandy do
  def run(path) do
    img  = CImg.load(path)

    Candy.apply(img)
    |> CImg.save("result.jpg")
  end
end
