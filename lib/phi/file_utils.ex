defmodule Phi.FileUtils do
  @moduledoc false

  @spec diff(String.t(), String.t()) :: integer
  def diff(p1, p2) do
    size1 = File.stat!(p1).size
    size2 = File.stat!(p2).size

    diff_bytes = size2 - size1
    signal = if diff_bytes > 0, do: "+", else: "-"

    diff = abs(diff_bytes)
    diff_percentage = round(100 * diff / size1)

    size1 = verbose_byte_size(size1)
    size2 = verbose_byte_size(size2)
    diff = "#{signal}#{verbose_byte_size(diff)}"
    diff_percentage = "#{signal}#{diff_percentage}"

    IO.puts("""
    Result:
    - #{Path.basename(p1)}: #{size1}
    - #{Path.basename(p2)}: #{size2} (#{diff}, #{diff_percentage}%)
    """)

    diff_bytes
  end

  @bytes_in_a_gigabyte 1_073_741_824
  @bytes_in_a_megabyte 1_048_576
  @bytes_in_a_kilobyte 1_024

  @spec verbose_byte_size(integer) :: String.t()
  def verbose_byte_size(size) do
    cond do
      size > @bytes_in_a_gigabyte -> "#{Float.round(size / @bytes_in_a_gigabyte, 2)} GB"
      size > @bytes_in_a_megabyte -> "#{Float.round(size / @bytes_in_a_megabyte, 2)} MB"
      size > @bytes_in_a_kilobyte -> "#{Float.round(size / @bytes_in_a_kilobyte, 2)} KB"
      true -> "#{size} B"
    end
  end
end
