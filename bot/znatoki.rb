# frozen_string_literal: true

require_relative 'common'

# rubocop:disable Lint/UnusedMethodArgument
def create_polls(event:, context:)
  chats = context.is_a?(Hash) && context.key?(:chats) ? context[:chats] : Bot::Chat.scan.select(&:znatoki)

  return SUCCESS_RESULT if chats.empty?

  options = Bot::PollOptions::Znatoki.new.options

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
