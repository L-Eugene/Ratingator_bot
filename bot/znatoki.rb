require_relative 'lib/common'

require 'rss'
require 'open-uri'
require 'chgk_rating'
require 'telegram/bot'

ANNOUNCE_REGEXP = %r{((?<date>\d+\.[IVX]+).*?)?tournament/(?<id>\d+).*?(?<time>\d{2}:\d{2})(?<online>.*zoom\.us)?}imx

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
SUCCESS_RESULT = { statusCode: 200 }

def roman_to_arabic(number)
  (%r{^[IVX]+$} === number.to_s.upcase ? ROMAN_MONTHS.find_index(number) + 1 : number).to_i
end

def localize_day_of_week(string)
  RUSSIAN_DAYS.inject(string) { |string, (en, ru)| string.gsub(/^#{en}/, ru) }
end

def cleanup_polls
  telegram = Telegram::Bot::Client.new(telegram_token)

  Chat.scan.select(&:znatoki_poll).each do |chat|
    telegram.api.unpin_chat_message(chat_id: chat.id, message_id: chat.znatoki_poll)
    chat.update(znatoki_poll: nil)
  end

  SUCCESS_RESULT
end

def create_polls
  chats = Chat.scan.select(&:znatoki)

  return SUCCESS_RESULT if chats.empty?

  options = URI.open('https://znatoki.info/forums/-/index.rss') do |rss|
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

      next nil if date < Time.new.to_datetime

      "#{localize_day_of_week date.strftime('%a')} #{date.strftime('%F %R')} #{record.type_name} \"#{record.long_name}\""
    end
  end.compact

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

    telegram.api.pin_chat_message(
      chat_id: chat.id,
      message_id: response['result']['message_id'],
    )

    chat.update(znatoki_poll: response['result']['message_id'])
  end

  SUCCESS_RESULT
end

def handler(event:, context:)
  send("#{event['action']}_polls") if ['create', 'cleanup'].include? event['action']
end
