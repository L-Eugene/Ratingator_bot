# frozen_string_literal: true

require 'telegram/bot'
require 'json'

require_relative 'lib/common'

# rubocop:disable Lint/UnusedMethodArgument
def unpin_messages(event:, context:)
  Bot::Chat.scan.each(&:unpin_messages!)

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument

# rubocop:disable Lint/UnusedMethodArgument
def message_handler(event:, context:)
  begin
    update = Telegram::Bot::Types::Update.new(JSON.parse(event['body']))
  rescue StandardError
    puts 'Invalid update structure', event['body']
  end

  return SUCCESS_RESULT if update&.message.nil?

  Bot::Command::Base.process(Bot::Chat.find_or_create(id: update.message.chat.id), update.message)

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument
