# frozen_string_literal: true

require 'telegram/bot'
require 'rating_chgk_v2'
require 'json'

require_relative 'lib/common'

def telegram
  @telegram ||= Telegram::Bot::Client.new(telegram_token)
end

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

def extra_poll_options(chat, message)
  list = message.text.split("\n").map(&:strip).grep_v(%r{^/})
  chat.update(extra_poll_options: list)

  text = <<~TXT
    Ко всем опросам от бота будут добавляться следующие варианты:
    #{list.map { |s| " - #{s}" }.join("\n")}
  TXT

  if list.empty?
    text = <<~TXT
      *Дополнительные варианты ответа удалены.*
      Если вы хотите их добавить - используйте команду /extra\\_poll\\_options со списком (отделяйте варианты переводом строки) или пришлите список в ответ на это сообщение.'
    TXT
  end

  telegram.api.send_message chat_id: chat.id, reply_to_message: message.message_id, parse_mode: 'Markdown', text: text
end

def action_disabled(message, feature = '')
  telegram.api.send_message(
    chat_id: message.chat.id,
    reply_to_message_id: message.message_id,
    text: "Функция #{feature} запрещена. Свяжитесь с владельцем бота."
  )

  SUCCESS_RESULT
end

def self_registration_disabled(message)
  telegram.api.send_message(
    chat_id: message.chat.id,
    reply_to_message_id: message.message_id,
    text: 'Управление слежением запрещено. Свяжитесь с владельцем бота.'
  )

  SUCCESS_RESULT
end

def only_admin_allowed(message)
  telegram.api.send_message(
    chat_id: message.chat.id,
    reply_to_message_id: message.message_id,
    text: 'Только администратор чата может выполнять эту команду.'
  )

  SUCCESS_RESULT
end

def admin?(options)
  return true if options[:chat].private?

  telegram.api
          .get_chat_administrators(chat_id: options[:chat].id)['result']
          .any? { |x| x['user']['id'].to_i == options[:user_id].to_i }
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

  chat = Bot::Chat.find_or_create(id: update.message.chat.id)

  return SUCCESS_RESULT if Bot::Command::Base.process(chat, update.message)

  case update.message.text
  when %r{^/znatoki_(on|off)}
    return action_disabled(update.message) unless ENV['ALLOW_ZNATOKI_POLLS']
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    chat.update(znatoki: %r{^/znatoki_on} =~ update.message.text)
  when %r{^/znatoki_force}
    return action_disabled(update.message) unless ENV['ALLOW_ZNATOKI_POLLS']
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    require_relative './znatoki'
    create_polls event: nil, context: { chats: [chat] }
  when %r{^/extra_poll_options}
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    extra_poll_options(chat, update.message)
  else
    if update.message&.reply_to_message&.text =~ %r{Дополнительные варианты удалены} && admin?(
      user_id: update.message.from.id, chat: chat
    )
      extra_poll_options(chat, update.message)
    end
  end

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument
