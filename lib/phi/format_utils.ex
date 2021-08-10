defmodule Phi.FormatUtils do
  @moduledoc false

  @spec age_index(String.t(), :from_18_to_80_by_10, keyword) :: integer
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

  def date(brazilian_date, :dd_mm_yyyy) do
    [day, month, year] = brazilian_date |> String.split("/") |> Enum.map(&String.to_integer/1)
    Date.new!(year, month, day)
  end
end
