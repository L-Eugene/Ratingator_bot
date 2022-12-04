# frozen_string_literal: true

require 'aws-record'
require 'date'
require 'json'
require 'rating_chgk_v2'
require 'telegram/bot'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib")
loader.setup

SUCCESS_RESULT = { statusCode: 200 }.freeze

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV.fetch('AWS_REGION', nil))
  client.get_secret_value(secret_id: ENV.fetch('SECRET_NAME', nil)).secret_string
end
