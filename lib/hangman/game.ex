defmodule Hangman.Game do
  
  alias __MODULE__

  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters:    [],
    used:       MapSet.new()
  )

  def new_game(word) do
    %Game{
      letters: String.codepoints(word)
    }
  end
  def new_game(), do: new_game(Dictionary.random_word)

  def make_move(game = %Game{game_state: state}, _guess) when state in [:won, :lost] do
    return_with_tally(game)
  end
  def make_move(game, guess) do
    game
    |> accept_move(guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  def tally(game) do
    %{
      game_state: game.game_state,
      turns_left: game.turns_left,
      letters:    reveal_guessed(game.letters, game.used),
      used:       MapSet.to_list(game.used)
    }
  end

  ######## PRIVATE FUNCTIONS ########

  defp accept_move(game, _guess, _already_guesses = true) do
    Map.put(game, :game_state, :already_used)
  end
  defp accept_move(game, guess, _already_guesses) do
    game
    |> Map.put(:used, MapSet.put(game.used, guess))
    |> score_guess(Enum.member?(game.letters, guess))
  end

  defp score_guess(game, _good_guess = true) do
    new_state = 
      game.letters
      |> MapSet.new()
      |> MapSet.subset?(game.used)
      |> maybe_won()

    Map.put(game, :game_state, new_state)
  end
  defp score_guess(game = %Game{turns_left: 1}, _not_good_guess) do
    Map.put(game, :game_state, :lost)
  end

  defp score_guess(game = %Game{turns_left: turns_left}, _not_good_guess) do
    %{ game | 
      game_state: :bad_guess,
      turns_left: turns_left - 1
    }
  end

  defp reveal_guessed(letters, used) do
    Enum.map(letters, fn letter -> reveal_letter(letter, MapSet.member?(used, letter)) end)
  end

  defp reveal_letter(letter, _in_word = true), do: letter
  defp reveal_letter(_letter, _not_in_word),   do: "_"

  defp maybe_won(true),  do: :won
  defp maybe_won(_),     do: :good_guess

  defp return_with_tally(game), do: {game, tally(game)}
end