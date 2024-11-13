# frozen_string_literal: true

# loading team ratings from chgk.gg
module RatingChgkV2
  module Models
    # Monkey-patch to add Team model data
    class TeamModel
      def ratings
        @ratings ||= ratings_data
      end

      def rating(id)
        ratings.detect { |r| r.id == id }
      end

      private

      # Getting team ratings from chgk.gg rating site
      def ratings_data
        ChgkGg::TeamRatingsReader.execute(id).items[0, 5]
      end
    end
  end
end
