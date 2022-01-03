require 'json'

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  client.get_secret_value(secret_id: ENV['SECRET_NAME']).secret_string
end

def dynamo
  require 'aws-sdk-dynamodb'
  Aws::DynamoDB::Client.new(region: ENV['AWS_REGION'])
end

def chat_list
  return { items: JSON.parse(File.read('../chat_list.json')) } unless ENV.key? 'AWS_REGION'

  dynamo.scan(table_name: ENV['DYNAMO_TABLE'])
end

def chat_watch(chat, team)
  dynamo.put_item(
    item: { chat_id: chat, team_id: team },
    table_name: ENV['DYNAMO_TABLE']
  )

  true
rescue
  false
end

def chat_unwatch(chat)
  dynamo.delete_item(
    key: { chat_id: chat },
    table_name: ENV['DYNAMO_TABLE']
  )

  true
rescue
  false
end
