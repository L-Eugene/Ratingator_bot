# frozen_string_literal: true

require 'rss'
require 'open-uri'

module Bot::PollOptions
  # Implementation of creating poll from announce on znatoki.info
  class Znatoki < Base
    # rubocop:disable Layout/LineLength
    ANNOUNCE_REGEXP = Regexp.new(
      '((?<date>\d+\.[IVXХ]+)\)?<.*?)?tournament/(?<id>\d+).*?(?<time>\d{2}:\d{2})(?<online>.*?(zoom\.us|discord\.gg))?',
      Regexp::IGNORECASE | Regexp::MULTILINE | Regexp::EXTENDED
    ).freeze
    # rubocop:enable Layout/LineLength

    private

    def fetch_data
      URI.open('https://znatoki.info/forums/-/index.rss') do |rss|
        feed = RSS::Parser.parse(rss)
        tournaments = feed.items.first.content_encoded.to_enum(:scan, ANNOUNCE_REGEXP).map { Regexp.last_match }

        chgk_client = RatingChgkV2.client

        @data = tournaments.map.with_index do |tournament, index|
          date = (tournament[:date] || tournaments[index - 1][:date]).split('.')
                                                                     .map { |x| Bot::Util.roman_to_arabic(x) }
                                                                     .reverse
                                                                     .unshift(Time.new.year)
                                                                     .push(*tournament[:time].split(':').map(&:to_i))

          date = DateTime.new(*date)

          record = chgk_client.tournament(tournament[:id])

          next nil if date < Date.today - 7

          OpenStruct.new(
            date:,
            type: record.type['name'],
            name: record.name,
            online: tournament[:online]
          )
        end.compact
      end
    end
  end
end
