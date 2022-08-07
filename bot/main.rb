# frozen_string_literal: true

require 'telegram/bot'
require 'chgk_rating'
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
    /venues - вывести список наблюдаемых площадок и инструкцию по управлению списком
    /random - выбрать случайный вариант из заданных
  TEXT
end

def randomize(message)
  mask = message.text.include?("\n") ? "\n" : ' '

  list = message.text
                .gsub(%r{^/[^\s]+\s}, '')
                .split(mask)
                .compact
                .map { |x| x.gsub(%r{[,\s]*$}, '') }

  if list.size < 2
    telegram.api.send_message(
      text: 'Слишком короткий список вариантов. ' \
            'Введите варианты, разделенные пробелом или переводом строки, в ответе на это сообщение.',
      chat_id: message.chat.id,
      reply_to_message_id: message.message_id,
      parse_mode: 'Markdown'
    )
    return
  end

  telegram.api.send_message(chat_id: message.chat.id, text: <<~TXT, parse_mode: 'Markdown')
    *Из следущих вариантов:* #{list.join(', ')}
    *Я выбрал* #{list.sample}
  TXT
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

def process_venues(chat, message)
  list = message.text.split("\n").map(&:strip).grep_v(%r{^/}).map(&:to_i)

  chat.update(venues: (chat.venues + list).uniq)

  text = <<~TXT
    *К списку наблюдения добавлены площадки:*
    #{list.join("\n")}
  TXT

  if list.empty?
    watched = chat.venues.map(&:to_i).map { |v| "#{v}. *удалить:* /venue\\_unwatch\\_#{v}" }.join("\n")

    text = <<~TXT
      *На текущий момент вы следите за следующими площадками:*
      #{chat.venues.empty? ? 'Список пуст' : watched}

      Если вы хотите добавить площадку для слежения - используйте команду /venues со списком id площадок (отделяйте варианты переводом строки) или пришлите список в ответ на это сообщение.
      Чтобы прекратить следить за площадкой - используйте команду из списка выше.
    TXT
  end

  telegram.api.send_message chat_id: chat.id, reply_to_message: message.message_id, parse_mode: 'Markdown', text: text
end

def unwatch_venue(chat, message)
  m = message.text.match(%r{/venue_unwatch_(?<venue_id>\d+)})

  text = 'Не удалось найти площадку с таким id'

  if m && chat.venues.include?(m[:venue_id].to_i)
    chat.update(venues: chat.venues - [m[:venue_id].to_i])

    text = "Площадка #{m[:venue_id]} успешно удалена"
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

  case update.message.text
  when %r{^/help|^/start}
    telegram.api.send_message(chat_id: update.message.chat.id, text: help_message, parse_mode: 'Markdown')
  when %r{^/watch\s[0-9]+}
    return self_registration_disabled(update.message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'
    return only_admin_allowed(update.message) unless admin?(userid: update.message.from.id, chat: chat)

    team_id = update.message.text.match(%r{/watch\s([0-9]+)})[1].to_i

    begin
      team = ChgkRating.client.team(team_id)
    rescue ChgkRating::Error => e
      telegram.api.send_message(chat_id: update.message.chat.id,
                                text: "Ошибка: #{JSON.parse(e.message)['error']['message']}")
      return SUCCESS_RESULT
    end

    if chat.update(team_id: team_id)
      telegram.api.send_message(chat_id: update.message.chat.id,
                                text: "Слежение за командой #{team.name} (##{team_id}) включено.")
    else
      telegram.api.send_message(chat_id: update.message.chat.id, text: 'Не удалось включить слежение за командой.')
    end
  when %r{^/znatoki_(on|off)}
    return action_disabled(update.message) unless ENV['ALLOW_ZNATOKI_POLLS']
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    chat.update(znatoki: %r{^/znatoki_on} =~ update.message.text)
  when %r{^/znatoki_force}
    return action_disabled(update.message) unless ENV['ALLOW_ZNATOKI_POLLS']
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    require_relative './znatoki'
    create_polls event: nil, context: { chats: [chat] }
  when %r{^/venues}
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    process_venues(chat, update.message)
  when %r{^/venue_unwatch}
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    unwatch_venue(chat, update.message)
  when %r{^/unwatch}
    return self_registration_disabled(update.message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    if chat.update(team_id: nil)
      telegram.api.send_message(chat_id: update.message.chat.id, text: 'Слежение за командой прекращено.')
    else
      telegram.api.send_message(chat_id: update.message.chat.id, text: 'Не удалось отключить слежение за командой.')
    end
  when %r{^/extra_poll_options}
    return only_admin_allowed(update.message) unless admin?(user_id: update.message.from.id, chat: chat)

    extra_poll_options(chat, update.message)
  when %r{^/random}
    randomize(update.message)
  else
    randomize(update.message) if update.message&.reply_to_message&.text =~ %r{^Слишком короткий список вариантов}

    if update.message&.reply_to_message&.text =~ %r{Дополнительные варианты удалены} && admin?(
      user_id: update.message.from.id, chat: chat
    )
      extra_poll_options(chat, update.message)
    end

    if update.message&.reply_to_message&.text =~ %r{вы следите за следующими площадками} && admin?(
      user_id: update.message.from.id, chat: chat
    )
      process_venues(chat, update.message)
    end
  end

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument
