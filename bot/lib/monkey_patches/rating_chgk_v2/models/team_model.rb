module MonkeyPatches::RatingChgkV2::Models::TeamModel
    # loading team ratings from MAII
    class ::RatingChgkV2::Models::TeamModel
        def ratings
            @ratings ||= ratings_data
        end

        def rating(id)
            ratings.detect { |r| r.id == id }
        end

        private

        # Getting team ratings from MAII rating site
        def ratings_data
            Maii::TeamRatingsReader.execute(id).items[0, 5]
        end
    end
end
