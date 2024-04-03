defmodule DemoWhisper do
  def run(path) do
    wav = Npy.load!(path)
    Whisper.apply(wav)
  end
end
