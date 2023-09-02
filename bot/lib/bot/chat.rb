# frozen_string_literal: true

module Bot
  # Database record of chat options
  class Chat
    include Aws::Record

    set_table_name ENV.fetch('DYNAMO_TABLE', nil)

    integer_attr :id, hash_key: true, database_attribute_name: 'chat_id'
    integer_attr :team_id
    boolean_attr :znatoki
    list_attr :pinned, default_value: []
    list_attr :venues, default_value: []
    list_attr :extra_poll_options, default_value: []

    def self.find_or_create(options)
      find(options) || new(options)
    end

    def private?
      id.positive?
    end

    def group?
      id.negative?
    end

    # Checks if chat member is admin
    def admin?(member)
      return true if private?

      telegram.api
              .get_chat_administrators(chat_id: id)['result']
              .any? { |x| x['user']['id'].to_i == member.to_i }
    end

    def pin_message(message_id, deadline = Date.today)
      telegram.api.pin_chat_message(chat_id: id, message_id:)

      update(pinned: pinned + [message_id:, deadline: deadline.to_s])
    end

    def unpin_messages!
      list = pinned.select { |p| Date.parse(p['deadline']) <= Date.today }

      return if list.empty?

      list.each do |p|
        telegram.api.unpin_chat_message(chat_id: id, message_id: p['message_id'].to_i)
      rescue Telegram::Bot::Exceptions::ResponseError => e
        puts "ERROR: #{e.class}: #{e.message}"
      end

      update(pinned: pinned - list)
    end

    private

    def telegram
      @telegram ||= Telegram::Bot::Client.new(telegram_token)
    end
  end
end
