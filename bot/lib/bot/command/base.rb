module Bot
  # Namespace for bot commands processors
  module Command
    class Base
      def self.process(chat, message)
        klasses = self.descendants.select { |klass| klass.match?(message) }
        return false if klasses.empty?

        klasses.each do |klass|
          puts "Processing command in #{klass.to_s} class"
          klass.process(chat, message)
        end

        true
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

      def self.cmd_help
        []
      end
    end
  end
end
