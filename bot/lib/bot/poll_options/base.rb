# frozen_string_literal: true

module Bot
  module PollOptions
    # Base class for getting announces and creating poll option lists
    class Base
      OPTION_LENGTH_LIMIT = 99

      attr_reader :data

      def initialize
        @data = []
        fetch_data
      end

      def options
        @data.map do |row|
          "#{Bot::Util.localize_day_of_week row.date.strftime('%a')} #{row.date.strftime('%F %R')} " \
            "#{row.type} #{row.name} #{row.online ? ' 🎧' : ''}"
        end.map { |s| s.length > OPTION_LENGTH_LIMIT ? "#{s[0..(OPTION_LENGTH_LIMIT - 3)]}..." : s }.sort
      end

      def descriptions
        @data.map do |row|
          next unless row&.tournament && row&.request

          <<~TEXT
            <a href="https://rating.chgk.info/tournament/#{row.tournament.id}">#{row.tournament.name}</a>
            #{row.tournament.questionQty.map { |_, v| v }.sum} вопросов (сложность #{row.tournament.difficultyForecast || 'не указана'})
            <b>Начало</b> #{row.date.strftime('%F в %R')} (UTC+3)
            <b>Редактор(ы):</b> #{row.tournament.editors.map { |e| "#{e['name']} #{e['surname']}" }.join(', ')}
            <b>Представитель:</b> #{row.request.representative['name']} #{row.request.representative['surname']}
            <b>Ведущий:</b> #{row.request.narrator['name']} #{row.request.narrator['surname']}
          TEXT
        end
      end

      private

      # Abstract method, should be implemented in a subclass
      #
      # Should get the list for upcoming games and fill the @data array with OpenStructs with next fields:
      #   * date - start date and time
      #   * type - tournament type
      #   * name - tournament name
      #   * online - online flag
      def fetch_data
        raise 'Method should be implemented in a subclass'
      end
    end
  end
end
