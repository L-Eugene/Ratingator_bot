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
                 "Площадка #{venue_name(match[:venue_id])} успешно удалена из списка наблюдения"
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
                      .select { |venue_id| venue_exists?(venue_id) }

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
        watched = chat.venues.map(&:to_i).map do |venue_id|
          "#{venue_name(venue_id)}. *удалить:* /venue\\_unwatch\\_#{venue_id}"
        end.join("\n")

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
          #{list.map { |venue_id| venue_name(venue_id) }.join("\n")}
        TXT
      end

      def self.cmd_help
        [['/venues', 'вывести список наблюдаемых площадок и инструкцию по управлению списком']]
      end

      def self.venue_name(venue_id)
        @@client ||= RatingChgkV2.client
        "#{@@client.venue(venue_id).name} (#{venue_id})"
      rescue RatingChgkV2::Error::NotFound
        'неизвестная площадка'
      end

      def self.venue_exists?(venue_id)
        @@client ||= RatingChgkV2.client
        @@client.venue(venue_id)
        true
      rescue RatingChgkV2::Error::NotFound
        false
      end

      private_class_method :venue_name, :venue_exists?
    end
  end
end
