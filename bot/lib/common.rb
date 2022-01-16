require 'json'
require 'aws-record'

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  client.get_secret_value(secret_id: ENV['SECRET_NAME']).secret_string
end

class Chat
  include Aws::Record

  set_table_name ENV['DYNAMO_TABLE']

  integer_attr :id, hash_key: true, database_attribute_name: 'chat_id'
  integer_attr :team_id
  boolean_attr :znatoki
  integer_attr :znatoki_poll

  def self.find_or_create(options)
    find(options) || new(options)
  end

  def private?
    id > 0
  end

  def group?
    id < 0
  end
end
