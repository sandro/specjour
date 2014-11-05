module Specjour
  module Colors

    VT100_COLORS = {
      :black => 30,
      :red => 31,
      :green => 32,
      :yellow => 33,
      :blue => 34,
      :magenta => 35,
      :cyan => 36,
      :white => 37
    }

    def colorize(text, color)
      if output.tty?
        "\e[#{VT100_COLORS[color]}m#{text}\e[0m"
      else
        text
      end
    end
  end
end
