module Bot
  # Namespace for bot commands processors
  module Command
    class Base
      def self.process(chat, message)
        klasses = self.descendants.select { |klass| klass.match?(message) }
        if klasses.empty?
          false
        else
          klasses.each { |klass| klass.process(chat, message) }
          true
        end
      end

      def self.match?(_message)
        # Nothing matches the base class
        false
      end

      def self.descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      def self.telegram
        @@telegram ||= Telegram::Bot::Client.new(telegram_token)
      end

      def self.telegram_exception(message, text)
        telegram.api.send_message(
          chat_id: message.chat.id,
          reply_to_message_id: message.message_id,
          text: text
        )

        SUCCESS_RESULT
      end

      def self.only_admin_allowed(message)
        telegram_exception(message, 'Только администратор чата может выполнять эту команду.')
      end

      def self.action_disabled(message)
        telegram_exception(message, "Команда запрещена. Свяжитесь с владельцем бота.")
      end
    end
  end
end

require_relative 'command_help'
require_relative 'command_rating'
require_relative 'command_venues'
require_relative 'command_random'
require_relative 'command_znatoki'
