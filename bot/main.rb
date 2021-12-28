require 'telegram/bot'
require 'json'

require_relative 'lib/common.rb'

def message_handler(event:, context:)
  secret = telegram_token
  chats = chat_list
  
  chats[:items].each do |chat|
    Telegram::Bot::Client.run(secret) { |bot| bot.api.send_message(chat_id: chat["ChatID"].to_i, text: 'Hello from AWS') }
  end


  {
    statusCode: 200,
    body: {
      message: "Hello World!",
      # location: response.body
    }.to_json
  }
end
