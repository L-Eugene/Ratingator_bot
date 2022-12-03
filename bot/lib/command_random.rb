module Bot
  module Command
    class Random < Base
      def self.match?(message)
        message.text =~ %r{^/random} || message&.reply_to_message&.text =~ %r{^Слишком короткий список вариантов}
      end

      def self.process(chat, message)
        list = parse_list message.text

        return usage(message) if list.size < 2

        telegram.api.send_message(chat_id: message.chat.id, text: <<~TXT, parse_mode: 'Markdown')
          *Из следущих вариантов:* #{list.join(', ')}
          *Я выбрал* #{list.sample}
        TXT
      end

      def self.parse_list(text)
        delimiter = text.include?("\n") ? "\n" : ' '

        text.gsub(%r{^/[^\s]+\s}, '').split(delimiter).compact.map { |x| x.gsub(%r{[,\s]*$}, '') }
      end

      def self.usage(message)
        telegram.api.send_message(
          text: 'Слишком короткий список вариантов. ' \
            'Введите варианты, разделенные пробелом или переводом строки, в ответе на это сообщение.',
          chat_id: message.chat.id,
          reply_to_message_id: message.message_id,
          parse_mode: 'Markdown'
        )
      end

      def self.cmd_help
        [['/random', 'выбрать случайный вариант из заданных']]
      end
    end
  end
end
