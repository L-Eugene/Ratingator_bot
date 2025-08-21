# frozen_string_literal: true

module Bot
  # Universal methods used anywhere in the code
  module Util
    class << self
      ROMAN_MONTHS = %w[I II III IV V VI VII VIII IX X XI XII].freeze

      RUSSIAN_DAYS = {
        'Mon' => 'Пнд',
        'Tue' => 'Вт',
        'Wed' => 'Ср',
        'Thu' => 'Чт',
        'Fri' => 'Пт',
        'Sat' => 'Сб',
        'Sun' => 'Вс'
      }.freeze

      def next_day(str)
        x = Date.parse(str)
        y = x > Date.today ? 0 : 7
        x + y
      end

      # return the Date object for next sunday. If today is sunday, return next sunday
      def next_sunday(today = Date.today)
        if today.sunday?
          today + 7
        else
          today + (7 - today.wday) % 7
        end
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

      def localize_day_of_week(day)
        RUSSIAN_DAYS.inject(day) { |s, (en, ru)| s.gsub(%r{^#{en}}, ru) }
      end

      def roman_to_arabic(number)
        number.tr!('Х', 'X')
        (%r{^[IVX]+$} =~ number.to_s.upcase ? ROMAN_MONTHS.find_index(number) + 1 : number).to_i
      end
    end
  end
end
