# frozen_string_literal: true

require_relative 'common'

# rubocop:disable Lint/UnusedMethodArgument
def weekly(event:, context:)
  input = JSON.parse(event['Records'].first['body'])

  rating = Bot::TeamRating.new RatingChgkV2.client.team(input['TeamID'])

  Telegram::Bot::Client.run(telegram_token) do |bot|
    message = rating.message

    input['ChatList'].each { |chat| bot.api.send_message(chat_id: chat.to_i, text: message, parse_mode: 'Markdown') }
  end

  SUCCESS_RESULT
end
# rubocop:enable Lint/UnusedMethodArgument

# rubocop:disable Lint/UnusedMethodArgument
# Filling the SQS queue with team list we want to track.
# Object should have TeamID and ChatList to send the result.
def initiate(event:, context:)
  require 'aws-sdk-sqs'
  team_chats = Bot::Chat.scan.each_with_object(Hash.new { |h, k| h[k] = [] }) do |chat, hash|
    hash[chat.team_id] << chat.id if chat.team_id
  end
  team_chats.each do |team, chats|
    sqs = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION', nil))
    sqs.send_message(queue_url: ENV.fetch('SQS_QUEUE_URL', nil),
                     message_body: { TeamID: team, ChatList: chats }.to_json)
    puts "Sent message: TeamID=#{team}, ChatList: #{chats.join ', '}"
  rescue StandardError => e
    puts "Error sending message: #{e.message}"
  end
end
# rubocop:enable Lint/UnusedMethodArgument
