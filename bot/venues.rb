require_relative 'lib/common'
require_relative 'lib/chgk_rating'

require 'telegram/bot'

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
    @@client ||= ChgkRating2.new

    @data = @@client.api_venues_requests_get_subresourceVenueSubresource(
      id: venue_id,
      page: 1,
      itemsPerPage: 50,
      pagination: true,
      'dateStart[strictly_before]': (Date.today + 1).to_s,
      'dateStart[strictly_after]': Date.today.to_s
    )['hydra:member']

    @@cache[venue_id] = self
  end

  def events
    @data.sort_by(&:dateStart).map do |event|
      {
        tournament: tournament(event.tournamentId),
        venue: event.venue,
        representative: event.representative,
        narrators: event.narrators,
        beginning: DateTime.parse(event.dateStart)
      }
    end
  end

  private

  def tournament(tournament_id)
    @@trnmt[tournament_id] ||= @@client.getTournamentItem(id: tournament_id)
  end

  reset_cache!
end

def handler(event:, context:)
  telegram = Telegram::Bot::Client.new(telegram_token)

  Bot::Chat.scan.each do |chat|
    chat.venues.each do |venue_id|
      games = VenueWatch[venue_id]

      items = games.events.map do |game|
        <<~TEXT
          <a href="https://rating.chgk.info/tournament/#{game[:tournament].id}">#{game[:tournament].name}</a>
          #{game[:tournament].questionQty.map { |_,v| v }.sum} вопросов (сложность #{game[:tournament].difficultyForecast || 'не указана'}) 
          <b>Начало</b> в #{game[:beginning].strftime('%F %R')}
          <b>Редактор(ы):</b> #{game[:tournament].editors.map{ |e| "#{e.name} #{e.surname}" }.join(', ')}
          <b>Представитель:</b> #{game[:representative].name} #{game[:representative].surname}
          <b>Ведущий:</b> #{game[:narrators].map { |n| "#{n.name} #{n.surname}" }.join(', ')}
        TEXT
      end

      next if items.empty?

      venue = games.events.first[:venue]

      response = telegram.api.send_message(chat_id: chat.id.to_i, text: <<~MESSAGE, parse_mode: 'HTML')
        <b>Сегодня на площадке #{venue['name']} состоится:</b>

        #{items.join("\n\n")}

        #ratingator #announcement
      MESSAGE

      chat.pin_message(response['result']['message_id'])
    end
  end

  { statusCode: 200 }
end