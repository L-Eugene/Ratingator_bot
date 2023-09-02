# frozen_string_literal: true

module Bot
  module Command
    # Commands for team rating tracking
    class Rating < Base
      def self.process(chat, message)
        if watch?(message)
          watch(chat, message)
        elsif unwatch?(message)
          unwatch(chat, message)
        end
      end

      def self.match?(message)
        watch?(message) || unwatch?(message)
      end

      def self.watch?(message)
        %r{^/watch\s[0-9]+} =~ message.text
      end

      def self.unwatch?(message)
        %r{^/unwatch} =~ message.text
      end

      def self.watch(chat, message)
        return registration_disabled(message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'
        return only_admin_allowed(message) unless chat.admin?(message.from.id)

        team_id = message.text.match(%r{/watch\s([0-9]+)})[1].to_i

        begin
          team = RatingChgkV2.client.team(team_id)
        rescue RatingChgkV2::Error => e
          telegram.api.send_message(chat_id: chat.id,
                                    text: "Ошибка: #{JSON.parse(e.message)['error']['message']}")
          return SUCCESS_RESULT
        end

        telegram.api.send_message(
          chat_id: chat.id,
          text: if chat.update(team_id:)
                  "Слежение за командой #{team.name} (##{team_id}) включено."
                else
                  'Не удалось включить слежение за командой.'
                end
        )
      end

      def self.unwatch(chat, message)
        return registration_disabled(message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'
        return only_admin_allowed(message) unless chat.admin?(message.from.id)

        telegram.api.send_message(
          chat_id: chat.id,
          text: if chat.update(team_id: nil)
                  'Слежение за командой прекращено.'
                else
                  'Не удалось отключить слежение за командой.'
                end
        )
      end

      def self.registration_disabled(message)
        telegram_exception(message, 'Управление слежением запрещено. Свяжитесь с владельцем бота.')
      end

      def self.cmd_help
        [
          ['/watch <team\\_id>', 'следить за рейтингом команды (один чат - одна команда)'],
          ['/unwatch', 'перестать следить за рейтингом команды']
        ]
      end
    end
  end
end
