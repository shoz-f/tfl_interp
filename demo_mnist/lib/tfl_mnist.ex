defmodule TflMnist do
  @moduledoc """
  MNIST inference engine.
  """

  # Setup Tensorflow lite interpreter with the model "mnist.tflite".
  use TflInterp, model: "priv/mnist.tflite"

  @doc """
  Apply MNIST to the image.
  
  ## Parameters
  
    * buff - binary of jpeg formated image.

  ## Examples
  
    ```Elixir
    iex> buf = File.read!("sample.jpg")
    iex> ans = TflMnist.apply(bun)
    ```
  """
  def apply(buff) do
    # preprocess
    bin = buff
      |> CImg.load_from_memory()
      |> CImg.get_gray(1)
      |> CImg.get_resize({28,28})
      |> CImg.to_flat(range: {0.0, 1.0})

    # prediction
    outputs =
      __MODULE__
      |> TflInterp.set_input_tensor(0, bin.data)
      |> TflInterp.invoke()
      |> TflInterp.get_output_tensor(0)

    # postprocess
    for <<score::little-float-32 <- outputs>> do score end
    |> Enum.with_index()
    |> Enum.max_by(fn {score, _} -> score end)
    |> elem(1)
  end
end
