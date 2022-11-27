# frozen_string_literal: true

require 'telegram/bot'
require 'json'

require_relative 'lib/common'

def help_message
  <<~TEXT
    /help - вывести это сообщение
    /watch <team\\_id> - следить за рейтингом команды (один чат - одна команда)
    /unwatch - перестать следить за рейтингом команды
    /znatoki\\_on - следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)
    /znatoki\\_off - перестать следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)
    /znatoki\\_force - получить опрос с анонсом [Гомельского клуба](http://znatoki.info) прямо сейчас
    /venues - вывести список наблюдаемых площадок и инструкцию по управлению списком
    /random - выбрать случайный вариант из заданных
  TEXT
end

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
