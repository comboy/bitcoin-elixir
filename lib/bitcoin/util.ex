defmodule Bitcoin.Util do

  # Random 64 bit nonce
  def nonce64, do: :rand.uniform(0xFF_FF_FF_FF_FF_FF_FF_FF) |> round

  def militime do
    {megas, s, milis} = :os.timestamp
    1.0e6*megas + s + milis * 1.0e-6
  end

end
