# frozen_string_literal: true

module MonkeyPatches
  module RatingChgkV2
    module Models
      module TeamModel
        # loading team ratings from MAII
        module ::RatingChgkV2
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

              # Getting team ratings from MAII rating site
              def ratings_data
                Maii::TeamRatingsReader.execute(id).items[0, 5]
              end
            end
          end
        end
      end
    end
  end
end
