defmodule DemoWhisper do
  def run(path) do
    Npy.load!(path).data
    |> Whisper.apply()
    |> Whisper.decode(Whisper.vocab())
  end
end
