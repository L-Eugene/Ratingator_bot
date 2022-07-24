require 'json'
require 'date'
require 'aws-record'

SUCCESS_RESULT = { statusCode: 200 }

def telegram_token
  return ENV['TELEGRAM_TOKEN'] if ENV.key? 'TELEGRAM_TOKEN'
  return File.read('../telegram_token.txt').chomp unless ENV.key? 'AWS_REGION'

  require 'aws-sdk-secretsmanager'
  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])
  client.get_secret_value(secret_id: ENV['SECRET_NAME']).secret_string
end

module Bot
  autoload :Util, "#{File.dirname(__FILE__ )}/util.rb"

  autoload :Chat, "#{File.dirname(__FILE__ )}/chat.rb"
end
