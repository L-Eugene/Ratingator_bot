# frozen_string_literal: true

require 'json'
require 'date'
require 'aws-record'

SUCCESS_RESULT = { statusCode: 200 }.freeze

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV.fetch('AWS_REGION', nil))
  client.get_secret_value(secret_id: ENV.fetch('SECRET_NAME', nil)).secret_string
end

module Bot
  autoload :Util, "#{File.dirname(__FILE__)}/util.rb"

  autoload :Chat, "#{File.dirname(__FILE__)}/chat.rb"
end
