defmodule FileUtils do
  require Logger

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

    Logger.debug("""
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

defmodule FormatUtils do
  @spec age_index(String.t(), :from_18_to_80_by_10) :: integer
  def age_index(age, :from_18_to_80_by_10, opts \\ []) do
    # 1: 0_29 2: 30_39, 3: 40_49, 4: 50_59, 5: 60_69, 6: 70_79, 7: 80_or_more

    age =
      if Keyword.get(opts, :float?, false) == true do
        age |> String.to_float() |> round()
      else
        String.to_integer(age)
      end

    age
    |> div(10)
    |> Kernel.-(1)
    |> max(1)
    |> min(7)
  end

  @spec city(String.t()) :: integer
  def city(city) do
    String.to_integer(city)
  end

  @spec city(String.t(), atom) :: integer
  def city(city, ets_table) do
    :ets.lookup_element(ets_table, city, 2)
  end

  @spec date(String.t(), :datetime) :: Date.t()
  def date(datetime, :datetime) do
    datetime
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end
end

defmodule XSV do
  @moduledoc """
  Manage CSV files with CLI xsv

  More info: <https://github.com/BurntSushi/xsv>
  """
  require Logger

  @spec csvfy(String.t(), String.t(), String.t()) :: String.t()
  def csvfy(input_csv_path, output_csv_path, delimiter) do
    Logger.debug("CSVfying #{Path.basename(input_csv_path)}")

    run(~w(fmt --delimiter #{delimiter}), input_csv_path, output_csv_path)
  end

  @spec join(String.t(), String.t(), String.t(), integer | String.t(), integer | String.t()) :: String.t()
  def join(input_1_path, input_2_path, output_path, column_1, column_2) do
    Logger.debug("Joining #{Path.basename(input_1_path)} and #{Path.basename(input_2_path)}")

    unless File.exists?(output_path) do
      run(~w(join --output #{output_path} #{column_1} #{input_1_path} #{column_2} #{input_2_path}))
    end

    output_path
  end

  @spec search(String.t(), String.t(), integer | String.t(), String.t()) :: String.t()
  def search(input_csv_path, output_csv_path, select, regex) do
    Logger.debug("Searching #{Path.basename(input_csv_path)}")

    select =
      if is_list(select) do
        Enum.join(select, ",")
      else
        select
      end

    run(~w(search --select #{select} #{regex}), input_csv_path, output_csv_path)
  end

  @spec select(String.t(), String.t(), list(integer)) :: String.t()
  def select(input_csv_path, output_csv_path, indexes) do
    Logger.debug("Selecting #{Path.basename(input_csv_path)}")

    indexes = Enum.join(indexes, ",")
    run(~w(select #{indexes}), input_csv_path, output_csv_path)
  end

  @spec sort(String.t(), String.t(), keyword) :: String.t()
  def sort(input_csv_path, output_csv_path, opts \\ []) do
    Logger.debug("Sorting #{Path.basename(input_csv_path)}")

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

defmodule Pipe do
  require Logger

  @type t :: %Pipe{
          index: integer,
          context: atom,
          path: String.t() | nil
        }

  defstruct index: 0,
            context: :default,
            path: nil

  @spec new(atom, String.t()) :: t()
  def new(context, input_path) do
    %Pipe{context: context, path: input_path}
  end

  @spec run(t(), String.t() | atom, (String.t(), String.t() -> any), keyword) :: t()
  def run(pipe_data, suffix, operation, opts \\ []) do
    index = pipe_data.index + 1

    result_path =
      opts
      |> Keyword.get(:result_dir, Path.dirname(pipe_data.path))
      |> result_path(index, pipe_data.context, suffix)

    if Keyword.get(opts, :force?, false) == true or File.exists?(result_path) == false do
      if Keyword.get(opts, :remove?, true) == true do
        File.rm_rf!(result_path)
      end

      operation.(pipe_data.path, result_path)

      FileUtils.diff(pipe_data.path, result_path)
    else
      Logger.debug("#{Path.basename(result_path)} already exists, operation skipped")
    end

    %Pipe{pipe_data | index: index, path: result_path}
  end

  @spec run_many(t(), String.t() | atom, list((String.t(), String.t() -> any)), keyword) :: t()
  def run_many(pipe_data, suffix, operations, opts \\ []) do
    index = pipe_data.index + 1

    result_path =
      opts
      |> Keyword.get(:result_dir, Path.dirname(pipe_data.path))
      |> result_path(index, pipe_data.context, suffix)

    if Keyword.get(opts, :force?, false) == true or File.exists?(result_path) == false do
      final_index = length(operations) + pipe_data.index - 1
      tmp_pipe_data = %Pipe{pipe_data | context: :tmp}

      Enum.reduce(operations, tmp_pipe_data, fn operation, current_pipe_data ->
        if current_pipe_data.index == final_index do
          run(%Pipe{pipe_data | path: current_pipe_data.path}, suffix, operation, opts)
        else
          run(current_pipe_data, suffix, operation, opts)
        end
      end)

      input_dir = Path.dirname(pipe_data.path)

      input_dir
      |> File.ls!()
      |> Enum.each(&if(&1 =~ "tmp", do: File.rm_rf!(Path.join(input_dir, &1))))
    else
      Logger.debug("#{Path.basename(result_path)} already exists, operation skipped")
    end

    %Pipe{pipe_data | index: index, path: result_path}
  end

  defp result_path(dir, index, context, suffix) do
    prefix = String.pad_leading(to_string(index), 3, "0")
    Path.join(dir, "#{prefix}_#{context}_#{suffix}.csv")
  end
end
