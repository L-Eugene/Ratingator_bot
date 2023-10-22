module MonkeyPatches::RatingChgkV2::Models::TeamTournamentModel
    # loading tournament results
    class ::RatingChgkV2::Models::TeamTournamentModel
        def tournament
            @tournament ||= RatingChgkV2.client.tournament @idtournament
        end

        def result
            @result ||= tournament.results(includeRatingB: true).detect { |r| r.team['id'] == @idteam }
        end
    end
end