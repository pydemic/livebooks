defmodule Phi.Pipe do
  @moduledoc false
  alias Phi.FileUtils
  alias Phi.Pipe

  @type t :: %Pipe{
          index: integer,
          context: atom,
          path: String.t() | nil,
          history: map()
        }

  defstruct index: 0,
            context: :default,
            path: nil,
            history: %{}

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
      IO.puts("#{Path.basename(result_path)} already exists, operation skipped")
    end

    %Pipe{pipe_data | index: index, path: result_path, history: Map.put(pipe_data.history, suffix, result_path)}
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
      IO.puts("#{Path.basename(result_path)} already exists, operation skipped")
    end

    %Pipe{pipe_data | index: index, path: result_path, history: Map.put(pipe_data.history, suffix, result_path)}
  end

  defp result_path(dir, index, context, suffix) do
    prefix = String.pad_leading(to_string(index), 3, "0")
    Path.join(dir, "#{prefix}_#{context}_#{suffix}.csv")
  end
end
