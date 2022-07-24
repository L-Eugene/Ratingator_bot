require_relative 'lib/common'

require 'rss'
require 'open-uri'
require 'chgk_rating'
require 'telegram/bot'

ANNOUNCE_REGEXP = %r{((?<date>\d+\.[IVX]+).*?)?tournament/(?<id>\d+).*?(?<time>\d{2}:\d{2})(?<online>.*?zoom\.us)?}imx

ROMAN_MONTHS = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII']
RUSSIAN_DAYS = {
  'Mon' => 'Пнд',
  'Tue' => 'Вт',
  'Wed' => 'Ср',
  'Thu' => 'Чт',
  'Fri' => 'Пт',
  'Sat' => 'Сб',
  'Sun' => 'Вс'
}

def roman_to_arabic(number)
  (%r{^[IVX]+$} === number.to_s.upcase ? ROMAN_MONTHS.find_index(number) + 1 : number).to_i
end

def localize_day_of_week(string)
  RUSSIAN_DAYS.inject(string) { |string, (en, ru)| string.gsub(/^#{en}/, ru) }
end

def get_poll_options
  URI.open('https://znatoki.info/forums/-/index.rss') do |rss|
    feed = RSS::Parser.parse(rss)
    tournaments = feed.items.first.content_encoded.to_enum(:scan, ANNOUNCE_REGEXP).map { Regexp.last_match }

    tournaments.map.with_index do |tournament, index|
      date = (tournament[:date] || tournaments[index-1][:date]).split('.')
                                                               .map { |x| roman_to_arabic(x) }
                                                               .reverse
                                                               .unshift(Time.new.year)
                                                               .push(*tournament[:time].split(':').map(&:to_i))

      date = DateTime.new(*date)

      record = ChgkRating.client.tournament(tournament[:id])

      next nil if date < Date.today

      "#{localize_day_of_week date.strftime('%a')} #{date.strftime('%F %R')} #{record.type_name} \"#{record.name}\" #{'🎧' if tournament[:online]}"
    end
  end.compact
end

def create_polls(event:, context:)
  chats = context[:chats] || Bot::Chat.scan.select(&:znatoki)

  return SUCCESS_RESULT if chats.empty?

  options = get_poll_options

  if options.empty?
    puts "No future games found. All items in past."
    return SUCCESS_RESULT
  end

  telegram = Telegram::Bot::Client.new(telegram_token)

  chats.each do |chat|
    response = telegram.api.send_poll(
      chat_id: chat.id,
      question: 'В эти выходные я приду играть',
      options: options.append('Не смогу сыграть').concat(chat.extra_poll_options),
      is_anonymous: false,
      allows_multiple_answers: true
    )

    chat.pin_message(response['result']['message_id'], Bot::Util.next_day('sunday'))
  end

  SUCCESS_RESULT
end
