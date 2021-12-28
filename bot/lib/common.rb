require 'telegram/bot'
require 'json'

def telegram_token
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  secret_name = 'rating_bot_token'

  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  get_secret_value_response = client.get_secret_value(secret_id: secret_name)
    
  get_secret_value_response.secret_string
end

def chat_list
  return { items: JSON.parse(File.read('../chat_list.json')) } unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-dynamodb'
  dynamodb_client = Aws::DynamoDB::Client.new(region: ENV['AWS_REGION'])

  dynamodb_client.scan(table_name: 'rating_bot_table')
end

