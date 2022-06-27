require 'json'
require 'date'
require 'aws-record'

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  client.get_secret_value(secret_id: ENV['SECRET_NAME']).secret_string
end

def next_day(str)
  x = Date.parse(str)
  y = x > Date.today ? 0 : 7
  x + y
end

class Chat
  include Aws::Record

  set_table_name ENV['DYNAMO_TABLE']

  integer_attr :id, hash_key: true, database_attribute_name: 'chat_id'
  integer_attr :team_id
  boolean_attr :znatoki
  list_attr :pinned, default_value: []
  list_attr :venues, default_value: []
  list_attr :extra_poll_options, default_value: []

  def self.find_or_create(options)
    find(options) || new(options)
  end

  def private?
    id.positive?
  end

  def group?
    id.negative?
  end

  def pin_message(message_id, deadline = Date.today)
    telegram = Telegram::Bot::Client.new(telegram_token)

    telegram.api.pin_chat_message(chat_id: id, message_id: message_id)

    update(pinned: pinned + [message_id: message_id, deadline: deadline.to_s])
  end

  def unpin_messages!
    list = pinned.select { |p| Date.parse(p['deadline']) <= Date.today }

    return if list.empty

    telegram = Telegram::Bot::Client.new(telegram_token)

    list.each { |p| telegram.api.unpin_chat_message(chat_id: id, message_id: p['message_id']) }

    update(pinned: pinned - list)
  end
end
