defmodule Phi.XSV do
  @moduledoc """
  Manage CSV files with CLI xsv

  More info: <https://github.com/BurntSushi/xsv>
  """

  @spec csvfy(String.t(), String.t(), String.t()) :: String.t()
  def csvfy(input_csv_path, output_csv_path, delimiter) do
    IO.puts("CSVfying #{Path.basename(input_csv_path)}")

    run(~w(fmt --delimiter #{delimiter}), input_csv_path, output_csv_path)
  end

  @spec full_join(String.t(), String.t(), String.t(), integer | String.t(), integer | String.t()) :: String.t()
  def full_join(input_1_path, input_2_path, output_path, column_1, column_2) do
    IO.puts("Full joining #{Path.basename(input_1_path)} and #{Path.basename(input_2_path)}")

    unless File.exists?(output_path) do
      run(~w(join --full --output #{output_path} #{column_1} #{input_1_path} #{column_2} #{input_2_path}))
    end

    output_path
  end

  @spec full_sort(String.t(), String.t()) :: String.t()
  def full_sort(input_csv_path, output_csv_path) do
    IO.puts("Full sorting #{Path.basename(input_csv_path)}")
    run(~w(sort), input_csv_path, output_csv_path)
  end

  @spec join(String.t(), String.t(), String.t(), integer | String.t(), integer | String.t()) :: String.t()
  def join(input_1_path, input_2_path, output_path, column_1, column_2) do
    IO.puts("Joining #{Path.basename(input_1_path)} and #{Path.basename(input_2_path)}")

    unless File.exists?(output_path) do
      run(~w(join --output #{output_path} #{column_1} #{input_1_path} #{column_2} #{input_2_path}))
    end

    output_path
  end

  @spec search(String.t(), String.t(), integer | String.t(), String.t()) :: String.t()
  def search(input_csv_path, output_csv_path, select, regex) do
    IO.puts("Searching #{Path.basename(input_csv_path)}")

    select =
      if is_list(select) do
        Enum.join(select, ",")
      else
        select
      end

    run(~w(search --select #{select} #{regex}), input_csv_path, output_csv_path)
  end

  @spec select(String.t(), String.t(), list(String.t() | integer)) :: String.t()
  def select(input_csv_path, output_csv_path, indexes) do
    IO.puts("Selecting #{Path.basename(input_csv_path)}")

    indexes = Enum.join(indexes, ",")
    run(~w(select #{indexes}), input_csv_path, output_csv_path)
  end

  @spec sort(String.t(), String.t(), keyword) :: String.t()
  def sort(input_csv_path, output_csv_path, opts \\ []) do
    IO.puts("Sorting #{Path.basename(input_csv_path)}")

    select = Keyword.get(opts, :select, [1]) |> Enum.join(",")

    if Keyword.get(opts, :non_numeric?, false) do
      run(~w(sort --select #{select} --numeric), input_csv_path, output_csv_path)
    else
      run(~w(sort --select #{select}), input_csv_path, output_csv_path)
    end
  end

  @spec run(list(String.t())) :: String.t()
  def run(args) do
    {result, 0} = System.cmd("xsv", args, stderr_to_stdout: true)
    result
  end

  @spec run(list(String.t()), String.t(), String.t()) :: String.t()
  def run(args, input_csv_path, output_csv_path) do
    {_result, 0} =
      System.cmd(
        "xsv",
        args ++ ~w(--output #{output_csv_path} #{input_csv_path}),
        stderr_to_stdout: true
      )

    output_csv_path
  end
end
