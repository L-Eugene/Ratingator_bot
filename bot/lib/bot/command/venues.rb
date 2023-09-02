# frozen_string_literal: true

module Bot
  module Command
    # Commands for venues monitoring
    class Venues < Base
      def self.process(chat, message)
        return only_admin_allowed(message) unless chat.admin?(message.from.id)

        return unwatch(chat, message) if unwatch?(message)

        watch(chat, message)
      end

      def self.match?(message)
        unwatch?(message) || watch?(message)
      end

      def self.unwatch?(message)
        message.text =~ %r{^/venue_unwatch_\d+}
      end

      def self.unwatch(chat, message)
        match = message.text.match(%r{/venue_unwatch_(?<venue_id>\d+)})

        text = if match && chat.venues.include?(match[:venue_id].to_i)
                 chat.update(venues: chat.venues - [match[:venue_id].to_i])
                 "Площадка #{match[:venue_id]} успешно удалена"
               else
                 'Не удалось найти площадку с таким id'
               end

        # TODO: use chat class to send messages
        telegram.api.send_message(
          chat_id: chat.id,
          reply_to_message: message.message_id,
          parse_mode: 'Markdown',
          text:
        )
      end

      def self.watch?(message)
        message.text =~ %r{^/venues(?:\s|$)} ||
          message&.reply_to_message&.text =~ %r{вы следите за следующими площадками}
      end

      def self.watch(chat, message)
        list = message.text.split("\n").map(&:strip).grep_v(%r{^/}).map(&:to_i)

        text = list.empty? ? venue_list(chat) : venue_list_update(chat, list)

        # TODO: use chat class to send messages
        telegram.api.send_message(
          chat_id: chat.id,
          reply_to_message: message.message_id,
          parse_mode: 'Markdown',
          text:
        )
      end

      def self.venue_list(chat)
        watched = chat.venues.map(&:to_i).map { |v| "#{v}. *удалить:* /venue\\_unwatch\\_#{v}" }.join("\n")

        <<~TXT
          *На текущий момент вы следите за следующими площадками:*
          #{chat.venues.empty? ? 'Список пуст' : watched}

          Если вы хотите добавить площадку для слежения - используйте команду /venues со списком id площадок (отделяйте варианты переводом строки) или пришлите список в ответ на это сообщение.
          Чтобы прекратить следить за площадкой - используйте команду из списка выше.
        TXT
      end

      def self.venue_list_update(chat, list)
        chat.update(venues: (chat.venues + list).uniq)

        <<~TXT
          *К списку наблюдения добавлены площадки:*
          #{list.join("\n")}
        TXT
      end

      def self.cmd_help
        [['/venues', 'вывести список наблюдаемых площадок и инструкцию по управлению списком']]
      end
    end
  end
end
