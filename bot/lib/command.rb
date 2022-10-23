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
    end
  end
end

require_relative 'command_help'
