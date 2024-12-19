# frozen_string_literal: true

module ChgkGg
  # Service object for fetching chgk.gg rating
  class TeamRatingsReader
    def self.execute(team_id)
      JSON.parse(
        Faraday.get("https://rating.chgk.gg/api/v1/b/teams/#{team_id}/releases.json").body,
        object_class: OpenStruct
      )
    end
  end
end
