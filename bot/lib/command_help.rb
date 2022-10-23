module Bot
  module Command
    class Help < Base
      HELP_MESSAGE = <<~TEXT
        /help - вывести это сообщение
        /watch <team\\_id> - следить за рейтингом команды (один чат - одна команда)
        /unwatch - перестать следить за рейтингом команды
        /znatoki\\_on - следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)
        /znatoki\\_off - перестать следить за анонсами на сайте [Гомельского клуба](http://znatoki.info)
        /znatoki\\_force - получить опрос с анонсом [Гомельского клуба](http://znatoki.info) прямо сейчас
        /venues - вывести список наблюдаемых площадок и инструкцию по управлению списком
        /random - выбрать случайный вариант из заданных
      TEXT

      def self.process(chat, _message)
        telegram.api.send_message chat_id: chat.id, text: HELP_MESSAGE, parse_mode: 'Markdown'
      end

      def self.match?(message)
        %r{^/help|^/start} =~ message.text
      end
    end
  end
end
