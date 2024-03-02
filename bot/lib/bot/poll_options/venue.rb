module Bot::PollOptions
    class Venue < Base
        def initialize(venue_id)
            @@client ||= RatingChgkV2.client

            @venue = @@client.venue venue_id

            super()
        end

        private

        def fetch_data
            @data = @venue.requests(
                'dateStart[strictly_before]': (Date.today + 3).to_s,
                'dateStart[strictly_after]': (Date.today + 2).to_s
            ).select { |r| %w(A N).include? r.status }.map do |request|
                tournament = @@client.tournament request.tournamentId

                OpenStruct.new(
                    date: DateTime.parse(request.dateStart),
                    type: tournament.type['name'],
                    name: tournament.name,
                    online: false
                )
            end
        end
    end
end