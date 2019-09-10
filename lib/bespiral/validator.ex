defmodule BeSpiral.Validator do
  @moduledoc "Validates resources"

  @doc """
  Validates email

  ## Examples

  iex> is_email?(nil)
  false

  iex> is_email?(1)
  false

  iex> is_email?(false)
  false
  """
  @spec is_email?(term) :: Boolean.t()
  def is_email?(email) when not is_binary(email), do: false

  @doc """
  Validates email

  ## Examples

  iex> is_email?("user@email.com")
  true

  iex> is_email?("user@email.com.br")
  true

  iex> is_email?("user@email")
  false
  """
  @spec is_email?(String.t()) :: Boolean.t()
  def is_email?(email) when is_binary(email) do
    pattern = ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+$/
    Regex.match?(pattern, email)
  end
end
