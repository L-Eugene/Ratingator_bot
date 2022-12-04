module Bot
  module Command
    class Help < Base
      def self.process(chat, _message)
        help_message = Base.descendants
                           .each_with_object([]) { |klass, arr| klass.cmd_help.each { |h| arr << h }  }
                           .map { |elm| "#{elm.first} - #{elm.last}" }
                           .join("\n")

        telegram.api.send_message chat_id: chat.id, text: help_message, parse_mode: 'Markdown'
      end

      def self.match?(message)
        %r{^/help|^/start} =~ message.text
      end

      def self.cmd_help
        [['/help', 'вывести это сообщение']]
      end
    end
  end
end
