# frozen_string_literal: true

module Bot
  # Universal methods used anywhere in the code
  module Util
    class << self
      def next_day(str)
        x = Date.parse(str)
        y = x > Date.today ? 0 : 7
        x + y
      end

      def arrow(number)
        char = case number
               when :zero?.to_proc
                 '➡️'
               when :positive?.to_proc
                 '⬆️'
               else
                 '⬇️'
               end

        "#{char} #{number.abs}"
      end

      def medal(number)
        values = ['🔸', '🥇', '🥈', '🥉']
        "#{(1..3).include?(number) ? values[number.to_i] : values.first} #{number}"
      end

      # Surround string with brackets if condition is true
      def surround(string, condition)
        condition ? "\\[#{string}]" : string
      end

      def type_char(tournament_type)
        case tournament_type
        when 'Асинхрон'
          'А'
        when 'Синхрон'
          'С'
        when 'Обычный'
          'Т'
        else
          '?'
        end
      end
    end
  end
end
