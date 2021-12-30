require 'telegram/bot'
require 'json'

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  secret_name = 'rating_bot_token'

  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  get_secret_value_response = client.get_secret_value(secret_id: secret_name)
    
  get_secret_value_response.secret_string
end

def dynamo
  require 'aws-sdk-dynamodb'
  Aws::DynamoDB::Client.new(region: ENV['AWS_REGION'])
end

def chat_list
  return { items: JSON.parse(File.read('../chat_list.json')) } unless ENV.key? 'AWS_REGION'

  dynamo.scan(table_name: 'rating_bot_table')
end

def chat_watch(chat, team)
  dynamo.put_item(
    item: { ChatID: chat, TeamID: team },
    table_name: 'rating_bot_table'
  )

  true
rescue
  false
end

def chat_unwatch(chat)
  dynamo.delete_item(
    key: { ChatID: chat },
    table_name: 'rating_bot_table'
  )

  true
rescue
  false
end
