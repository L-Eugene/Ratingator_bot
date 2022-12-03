module Bot
  module Command
    class Znatoki < Base
      LIST_EMPTY_MESSAGE = <<~TXT.freeze
        *Дополнительные варианты ответа удалены.*
        Если вы хотите их добавить - используйте команду /extra\\_poll\\_options со списком (отделяйте варианты переводом строки) или пришлите список в ответ на это сообщение.'
      TXT

      def self.match?(message)
        switch?(message) || force?(message) || extra_poll_options?(message)
      end

      def self.switch?(message)
        message.text =~ %r{^/znatoki_(on|off)}
      end

      def self.switch(chat, message)
        chat.update(znatoki: %r{^/znatoki_on} =~ message.text)
      end

      def self.force?(message)
        message.text =~ %r{^/znatoki_force}
      end

      def self.force(chat, message)
        require_relative '../znatoki'
        create_polls event: nil, context: { chats: [chat] }
      end

      def self.extra_poll_options?(message)
        message.text =~ %r{^/extra_poll_options} ||
          message&.reply_to_message&.text =~ %r{Дополнительные варианты ответа удалены}
      end

      def self.extra_poll_options(chat, message)
        list = message.text.split("\n").map(&:strip).grep_v(%r{^/})
        chat.update(extra_poll_options: list)

        text = list.empty? ? LIST_EMPTY_MESSAGE : <<~TXT
          Ко всем опросам от бота будут добавляться следующие варианты:
          #{list.map { |s| " - #{s}" }.join("\n")}
        TXT

        telegram.api.send_message chat_id: chat.id, reply_to_message: message.message_id, parse_mode: 'Markdown', text: text
      end

      def self.process(chat, message)
        return action_disabled(message) unless ENV['ALLOW_ZNATOKI_POLLS']
        return only_admin_allowed(message) unless chat.admin? message.from.id

        return extra_poll_options(chat, message) if extra_poll_options? message

        return force(chat, message) if force? message

        switch(chat, message)
      end

      def self.cmd_help
        [
          ['/znatoki\\_on', 'следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)'],
          ['/znatoki\\_off', 'перестать следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)'],
          ['/znatoki\\_force', 'получить опрос с анонсом [Гомельского клуба](http://znatoki.info) прямо сейчас']
        ]
      end
    end
  end
end
