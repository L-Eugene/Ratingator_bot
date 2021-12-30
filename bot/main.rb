require 'telegram/bot'
require 'chgk_rating'
require 'json'

require_relative 'lib/common.rb'

SUCCESS_RESULT = { statusCode: 200 }

def telegram
  @telegram ||= Telegram::Bot::Client.new(telegram_token)
end

def randomize(message)
  mask = message.text.include?("\n") ? "\n" : ' '
  
  list = message.text
                .gsub(%r{^\/[^\s]+\s}, '')
                .split(mask)
                .compact
                .map { |x| x.gsub(%r{[,\s]*$}, '') }
  
  if list.size < 2
    telegram.api.send_message(
      text: 'Слишком короткий список вариантов. Введите варианты, разделенные пробелом или переводом строки, в ответе на это сообщение.',
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

def self_registration_disabled(message)
  telegram.api.send_message(
    chat_id: message.chat.id,
    reply_to_message_id: message.message_id,
    text: 'Управление слежением запрещено. Свяжитесь с владельцем бота.'
  )

  SUCCESS_RESULT
end

def message_handler(event:, context:)
  begin
    update = Telegram::Bot::Types::Update.new(JSON.parse event['body'])
  rescue
    puts "Invalid update structure", event['body']
  end
  
  return SUCCESS_RESULT if update&.message.nil?

  case update.message.text
  when %r{^/watch\s[0-9]+}
    return self_registration_disabled(update.message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'

    team_id = update.message.text.match(%r{/watch\s([0-9]+)})[1].to_i

    begin
      team = ChgkRating.client.team(team_id)
    rescue
      telegram.api.send_message(chat_id: update.message.chat.id, text: "Ошибка: #{JSON.parse(e.message)["error"]["message"]}")
      return SUCCESS_RESULT
    end

    if chat_watch(update.message.chat.id, team_id)
      telegram.api.send_message(chat_id: update.message.chat.id, text: "Слежение за командой #{team.name} (##{team_id}) включено.")
    else
      telegram.api.send_message(chat_id: update.message.chat.id, text: "Не удалось включить слежение за командой.")
    end
  when %r{^/unwatch}
    return self_registration_disabled(update.message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'

    if chat_unwatch(update.message.chat.id)
      telegram.api.send_message(chat_id: update.message.chat.id, text: "Слежение за командой прекращено.")
    else
      telegram.api.send_message(chat_id: update.message.chat.id, text: "Не удалось отключить слежение за командой.")
    end
  when %r{^/random}
    randomize(update.message)
  else
    randomize(update.message) if update.message&.reply_to_message&.text =~ %r{^Слишком короткий список вариантов}
  end

  SUCCESS_RESULT
end
