# Semantic Segmentation for Self Driving Cars: UNet

```elixir
Mix.install([
  {:kino, "~> 0.6.1"},
  {:req, "~> 0.2.2"},
  {:nx, "~> 0.2.1"},
  {:cimg, github: "shoz-f/cimg_ex"},
  {:tfl_interp, path: "../tfl_interp"}
])

Req.get!("https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/unet.tflite").body
|> then(fn x -> File.write!("./unet.tflite", x) end)
```

## Inference module of UNet

```elixir
defmodule Unet do
  use TflInterp, model: "./unet.tflite"

  import Nx.Defn

  @unet_shape {512, 512}

  defn postproc(bin) do
    bin
    |> Nx.reshape({512, 512, 32})
    |> Nx.argmax(axis: 2)
    |> Nx.as_type({:u, 8})
  end

  def apply(img) do
    # save original shape
    {w, h, _, _} = CImg.shape(img)

    # preprocess
    bin =
      CImg.builder(img)
      |> CImg.resize(@unet_shape)
      |> CImg.to_binary()

    # prediction
    outputs =
      session()
      |> TflInterp.set_input_tensor(0, bin)
      |> TflInterp.run()
      |> TflInterp.get_output_tensor(0)
      |> Nx.from_binary({:f, 32})
      |> Nx.reshape({512, 512, 32})
      |> Nx.argmax(axis: 2)
      |> Nx.as_type({:u, 8})

    #      |> postproc()

    # postprocess
    Nx.to_binary(outputs)
    |> CImg.from_binary(512, 512, 1, 1, [{:dtype, "<u1"}])
    |> CImg.resize({w, h})
  end
end

Unet.start_link([])
```

```elixir
TflInterp.info(Unet)
```

## Apply to a sample image

```elixir
input =
  Req.get!("https://github.com/shoz-f/tfl_interp/blob/main/demo_livebook/sample.jpg?raw=true").body
  |> CImg.from_binary()

mask =
  Unet.apply(input)
  |> CImg.color_mapping(:lines)

input
|> CImg.blend(mask)
|> CImg.resize(0.5)
|> CImg.display_kino(:jpeg)
```
