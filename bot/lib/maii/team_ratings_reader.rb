# frozen_string_literal: true

module Maii
  # Service object for fetching MAII rating
  class TeamRatingsReader
    def self.execute(team_id)
      JSON.parse(
        Faraday.get("https://rating.maii.li/api/v1/b/teams/#{team_id}/releases.json").body,
        object_class: OpenStruct
      )
    end
  end
end
