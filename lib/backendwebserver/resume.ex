
defmodule RandomTextGenerator do

  require Logger

  @moduledoc """
  Random Text Generator
  """
  defstruct grammar_file: nil, grammar_rules: %{}, start_symbol: nil

  @doc """
  Defining what the Random Number Generator class is
  Creates a new random text gen object given a `grammar_file`
  """
  def new(grammar_file) do
    %RandomTextGenerator{grammar_file: grammar_file}
    |> read_grammar_rules()
  end

  # Reads grammar rules from the file and
  # does initial massaging before processing them
  # Returns `rtg` struct
  defp read_grammar_rules(%RandomTextGenerator{} = rtg) do

    # Read/load everything in the file's content
    lines =
      File.read!(rtg.grammar_file)
        # Massage: Split on new line and strip trailing whitespace
        |> String.split("\n", trim: true)

    # Process the lines to extract the grammar rules
    # Startng from our lines, empty grammar set, and an unknown start symbol
    {grammar, rtg} = process_lines(lines, %{}, nil)

    # Update and return the `rtg` struct with the extracted grammar rules
    %{rtg | grammar_rules: grammar}
  end

  # act as a termination for the recursion, where it returns the results accumulated so far
  defp process_lines([], grammar, start_symbol), do: {grammar, %RandomTextGenerator{start_symbol: start_symbol}}

  # process a line starting with "{" which indicates the start of a rule
  defp process_lines(["{" | line], grammar, start_symbol) do

    # consume a rule defined between "{" and "}"
    {non_terminal, productions, rest} = consume_rule(line)

    # update the grammar with the new rule
    updated_grammar = Map.put(grammar, non_terminal, productions)

    # continue processing the remaining lines
    process_lines(rest, updated_grammar, start_symbol || non_terminal)

  end

  defp process_lines(["}" | _], _, _), do: raise "Error: } misplaced when starting new production set"

  # Skip any line that doesn't start with "{"
  defp process_lines([_ | line], grammar, start_symbol), do: process_lines(line, grammar, start_symbol)

  # Consume a rule defined between "{" and "}"
  defp consume_rule([non_terminal_head | rest]) do

    # Scan for a pattern enclosed in carrot brackets (`<` and `>`)
    case Regex.scan(~r/<(.+?)>/, non_terminal_head) do

      # If a single match with one capture group is found
      [[captured_non_terminal, _]] ->

        # get the productions using that `rest` structure when
        # we prepended the non_terminal to it
        {productions, rest} = collect_productions(rest, [])

        # return what we need to update the grammar rules dictionary
        {captured_non_terminal, productions, rest}

      # If the expected pattern isn't found, e.g. no angle brackets
      _ ->
        raise "Error: invalid line format, expected a non-terminal enclosed in '<>'"
    end
  end

  # Collect productions until a "}" is encountered
  # Reverse is necessary here because it was put in reverse for efficiency
  defp collect_productions(["}" | line], productions), do: {Enum.reverse(productions), line}

  defp collect_productions(["{" | _], _), do: raise "Error: { found instead of production or }"

  # If a line ends with ";", it's a production
  defp collect_productions([head_symbol | line], productions) do

    if String.ends_with?(head_symbol, ";") do
      # extract the production by trimming and removing the trailing ";"
      # and here will error out if there is no semi colon found
      prod = String.trim(String.trim_trailing(head_symbol, ";"))

      # recursively collect more productions
      # prepends extraction to productions
      collect_productions(line, [prod | productions])
    end
  end

  # Starts processing with the start symbol of the grammar
  # Initialize start symbol in our symbols to read list, grammar rules,
  # and result stack
  def run(rtg), do: process_stack([rtg.start_symbol], rtg.grammar_rules, [])

  # When the stack is empty, we've finished generating the random text
  defp process_stack([], _, result) do

    # Reverse the output because of the definition of a stack structure
    result = Enum.reverse(result)

    # Create a string when we join the list on spaces
    result_string = Enum.join(result, " ")

    # Massage the result so it comes out pretty
    result_string = String.replace(result_string, ~r/\s(\\n|[.,])/, "\\1")

    # Return the generated text
    result_string
  end

  # Processes a non-terminal symbol
  # Given the current symbol that is prepended to rest of stack,
  # grammar rules dict, and the resulting stack
  defp process_stack([curr_symbol | rest_of_stack], grammar_rules, result)
       # Checks before run that there is a key provided by curr_symbol in grammar_rules
       when is_map_key(grammar_rules, curr_symbol) do

    # Retrieve a random production for the current non-terminal symbol.
    content = get_content(curr_symbol, grammar_rules)

    # Continue processing with the chosen production prepended to the stack.
    process_stack(content ++ rest_of_stack, grammar_rules, result)

  end

  # Processes a terminal symbol
  # Prepend the terminal symbol to the result list
  defp process_stack([terminal | rest_of_stack], grammar_rules, result) do
    # the only thing this does is prepend terminal to the results
    # also, prepending because it's for effiency in time
    process_stack(rest_of_stack, grammar_rules, [terminal | result])
  end

  defp get_content(curr_symbol, grammar_rules) do
    # Fetch all possible productions for the current non-terminal.
    productions = grammar_rules[curr_symbol]

    # Checks if list is empty before choosing a random production
    if !Enum.empty?(productions) do
      production = Enum.random(productions)
      String.split(production)
    else
      raise "Errors: No productions found"
    end
  end
end
