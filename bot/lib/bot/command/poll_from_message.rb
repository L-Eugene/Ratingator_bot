# frozen_string_literal: true

module Bot
    module Command
        # Poll command
        class PollFromMessage < Base
            def self.match?(message)
                (message.text || '').lines.count { |line| line.match?(/^\[.{,6}\]/) } >= 3
            end
        
            def self.process(chat, message)
                options = message.text.lines
                                 .select { |line| line.match(/^\[(.+?)\]\s*(.+)$/) }
                                 .map(&:strip)
                                 .map { |line| line.size > 100 ? "#{line[0..96]}..." : line }

                telegram = Telegram::Bot::Client.new(telegram_token)

                options.each_slice(10 - chat.extra_poll_options.size) do |option_group|
                    telegram.api.send_poll(
                        chat_id: chat.id,
                        question: 'Выберите варианты:',
                        options: option_group.concat(chat.extra_poll_options),
                        is_anonymous: false,
                        reply_to_message_id: message.message_id,
                        allows_multiple_answers: true
                    )
                end

                true
            end
        end
    end
end