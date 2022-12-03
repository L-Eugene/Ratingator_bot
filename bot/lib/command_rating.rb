require 'rating_chgk_v2'

module Bot
  module Command
    class Rating < Base
      def self.process(chat, message)
        case
        when watch?(message)
          watch(chat, message)
        when unwatch?(message)
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
          text: chat.update(team_id: team_id) ?
                  "Слежение за командой #{team.name} (##{team_id}) включено." :
                  'Не удалось включить слежение за командой.'
        )
      end

      def self.unwatch(chat, message)
        return registration_disabled(message) if ENV['ALLOW_SELF_REGISTRATION'] == 'false'
        return only_admin_allowed(message) unless chat.admin?(message.from.id)

        telegram.api.send_message(
          chat_id: chat.id,
          text: chat.update(team_id: nil) ?
                  'Слежение за командой прекращено.' :
                  'Не удалось отключить слежение за командой.'
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

