# frozen_string_literal: true

require_relative 'common'

require 'rss'
require 'open-uri'

ANNOUNCE_REGEXP = Regexp.new(
  '((?<date>\d+\.[IVXХ]+)\)?<.*?)?tournament/(?<id>\d+).*?(?<time>\d{2}:\d{2})(?<online>.*?(zoom\.us|discord\.gg))?',
  Regexp::IGNORECASE | Regexp::MULTILINE | Regexp::EXTENDED
).freeze

ROMAN_MONTHS = %w[I II III IV V VI VII VIII IX X XI XII].freeze
RUSSIAN_DAYS = {
  'Mon' => 'Пнд',
  'Tue' => 'Вт',
  'Wed' => 'Ср',
  'Thu' => 'Чт',
  'Fri' => 'Пт',
  'Sat' => 'Сб',
  'Sun' => 'Вс'
}.freeze

def roman_to_arabic(number)
  number.tr!('Х', 'X')
  (%r{^[IVX]+$} =~ number.to_s.upcase ? ROMAN_MONTHS.find_index(number) + 1 : number).to_i
end

def localize_day_of_week(string)
  RUSSIAN_DAYS.inject(string) { |s, (en, ru)| s.gsub(%r{^#{en}}, ru) }
end

def poll_options
  URI.open('https://znatoki.info/forums/-/index.rss') do |rss|
    feed = RSS::Parser.parse(rss)
    tournaments = feed.items.first.content_encoded.to_enum(:scan, ANNOUNCE_REGEXP).map { Regexp.last_match }

    chgk_client = RatingChgkV2.client

    tournaments.map.with_index do |tournament, index|
      date = (tournament[:date] || tournaments[index - 1][:date]).split('.')
                                                                 .map { |x| roman_to_arabic(x) }
                                                                 .reverse
                                                                 .unshift(Time.new.year)
                                                                 .push(*tournament[:time].split(':').map(&:to_i))

      date = DateTime.new(*date)

      record = chgk_client.tournament(tournament[:id])

      next nil if date < Date.today

      "#{localize_day_of_week date.strftime('%a')} #{date.strftime('%F %R')} #{record.type['name']} " \
        "\"#{record.name}\"#{tournament[:online] ? ' 🎧' : ''}"
    end
  end.map { |s| s.length > 99 ? "#{s[0..96]}..." : s }.compact
end

# rubocop:disable Lint/UnusedMethodArgument
def create_polls(event:, context:)
  chats = context.is_a?(Hash) && context.key?(:chats) ? context[:chats] : Bot::Chat.scan.select(&:znatoki)

  return SUCCESS_RESULT if chats.empty?

  options = poll_options

  if options.empty?
    puts 'No future games found. All items in past.'
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
# rubocop:enable Lint/UnusedMethodArgument
