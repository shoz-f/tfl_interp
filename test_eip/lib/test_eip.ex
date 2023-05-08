defmodule TestEip do
  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/test_eip.tflite",
    inputs: [f32: {1,10,10,1}],
    outputs: [f32: {1,10,10,9}]

  def apply(t) do
    # prediction
    session()
      |> NNInterp.set_input_tensor(0, Nx.to_binary(t))
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> Nx.from_binary(:f32) |> Nx.reshape({1,10,10,:auto})
  end
end
