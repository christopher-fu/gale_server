defimpl Poison.Encoder, for: Timex.DateTime do
  use Timex
  def encode(date, options) do
    Poison.Encoder.BitString.encode(Timex.format!(date, "{ISO:Extended:Z}"), options)
  end
end
