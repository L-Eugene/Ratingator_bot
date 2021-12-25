require 'aws-sdk-secretsmanager'
require 'aws-sdk-dynamodb'
require 'telegram/bot'
require 'json'

def message_handler(event:, context:)
  secret_name = 'rating_bot_token'
  region_name = 'eu-west-1'

  client = Aws::SecretsManager::Client.new(region: region_name)
  get_secret_value_response = client.get_secret_value(secret_id: secret_name)
    
  secret = get_secret_value_response.secret_string

  dynamodb_client = Aws::DynamoDB::Client.new(region: region_name)

  result = dynamodb_client.scan(table_name: 'rating_bot_table')
  
  result[:items].each do |chat|
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
