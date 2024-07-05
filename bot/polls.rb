# frozen_string_literal: true

require_relative 'common'

# rubocop:disable Lint/UnusedMethodArgument
def create_polls(event:, context:)
  venues = {}

  Bot::Chat.scan.each do |chat|
    chat.venues.map(&:to_i).each do |venue_id|
      venues[venue_id] ||= Bot::PollOptions::Venue.new(venue_id)

      if venues[venue_id].options.empty?
        puts "No future games found for venue #{venue_id}. All items in past."
        next
      end

      telegram = Telegram::Bot::Client.new(telegram_token)

      message = telegram.api.send_poll(
        chat_id: chat.id,
        question: 'Я приду играть',
        options: venues[venue_id].options.dup.append('Не смогу сыграть').concat(chat.extra_poll_options),
        is_anonymous: false,
        allows_multiple_answers: true
      )

      chat.pin_message(message.message_id, Bot::Util.next_day('sunday'))

      next if venues[venue_id].descriptions.empty?

      telegram.api.send_message(
        chat_id: chat.id,
        reply_to_message_id: message.message_id,
        text: venues[venue_id].descriptions.join("\n\n"),
        link_preview_options: Telegram::Bot::Types::LinkPreviewOptions.new(is_disabled: true),
        parse_mode: 'HTML'
      )
    end
  end

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument
