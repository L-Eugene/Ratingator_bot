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
        end.map { |s| s.length > OPTION_LENGTH_LIMIT ? "#{s[0..(OPTION_LENGTH_LIMIT - 3)]}..." : s }
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
