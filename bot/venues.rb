# frozen_string_literal: true

require_relative 'common'

# rubocop:disable Style/ClassVars
# Class for venue games tracking
class VenueWatch
  def self.[](venue_id)
    return @@cache[venue_id] if @@cache.key? venue_id

    new venue_id
  end

  def self.reset_cache!
    # Cache for venues data
    @@cache = {}
    # Cache for tournament data
    @@trnmt = {}
  end

  def initialize(venue_id)
    @@client ||= RatingChgkV2.client

    @venue = @@client.venue venue_id

    @data = @venue.requests(
      'dateStart[strictly_before]': (Date.today + 1).to_s,
      'dateStart[strictly_after]': Date.today.to_s
    ).select { |r| r.status == 'A' }

    @@cache[venue_id] = self
  end

  def events
    @data.sort_by(&:dateStart).map do |event|
      {
        tournament: tournament(event.tournamentId),
        venue: @venue,
        representative: event.representative,
        narrator: event.narrator,
        beginning: DateTime.parse(event.dateStart)
      }
    end
  end

  private

  def tournament(tournament_id)
    @@trnmt[tournament_id] ||= @@client.tournament tournament_id
  end

  reset_cache!
end
# rubocop:enable Style/ClassVars

# rubocop:disable Lint/UnusedMethodArgument
def handler(event:, context:)
  telegram = Telegram::Bot::Client.new(telegram_token)

  Bot::Chat.scan.each do |chat|
    chat.venues.each do |venue_id|
      games = VenueWatch[venue_id.to_i]

      items = games.events.map do |game|
        <<~TEXT
          <a href="https://rating.chgk.info/tournament/#{game[:tournament].id}">#{game[:tournament].name}</a>
          #{game[:tournament].questionQty.map { |_, v| v }.sum} вопросов (сложность #{game[:tournament].difficultyForecast || 'не указана'})
          <b>Начало</b> #{game[:beginning].strftime('%F в %R')}
          <b>Редактор(ы):</b> #{game[:tournament].editors.map { |e| "#{e['name']} #{e['surname']}" }.join(', ')}
          <b>Представитель:</b> #{game[:representative]['name']} #{game[:representative]['surname']}
          <b>Ведущий:</b> #{game[:narrator]['name']} #{game[:narrator]['surname']}
        TEXT
      end

      next if items.empty?

      venue = games.events.first[:venue]

      response = telegram.api.send_message(chat_id: chat.id.to_i, text: <<~MESSAGE, parse_mode: 'HTML')
        <b>Сегодня на площадке #{venue.name} состоится:</b>

        #{items.join("\n\n")}

        #ratingator #announcement
      MESSAGE

      chat.pin_message(response['result']['message_id'])
    end
  end

  { statusCode: 200 }
end
# rubocop:enable Lint/UnusedMethodArgument
