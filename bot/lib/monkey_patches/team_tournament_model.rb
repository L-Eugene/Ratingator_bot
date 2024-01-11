# frozen_string_literal: true

module RatingChgkV2
  module Models
    # Monkey-patch to add tournament results data
    class TeamTournamentModel
      def tournament
        @tournament ||= RatingChgkV2.client.tournament @idtournament
      end

      def result
        @result ||= tournament.results(includeRatingB: true).detect { |r| r.team['id'] == @idteam }
      end
    end
  end
end
