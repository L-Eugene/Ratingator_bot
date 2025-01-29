# frozen_string_literal: true

module Bot
  # The ChatLoader class is responsible for loading chat data
  # from the database or creating a new one if it doesn't exist.
  #
  # @example
  #   loader = Bot::ChatLoader.new(chat_id)
  #   chat = loader.load
  #
  # @param chat_id [Integer] the ID of the chat to load or create
  #
  # @!attribute [r] chat_id
  #   @return [Integer] the ID of the chat
  #
  # @!method initialize(chat_id)
  #   Creates a new instance of ChatLoader.
  #   @param chat_id [Integer] the ID of the chat to load or create
  #
  # @!method load
  #   Loads the chat from the database or creates a new one if it doesn't exist.
  #   @return [Chat] the loaded or newly created chat
  class ChatLoader
    def initialize(chat_id)
      @chat_id = chat_id
    end

    def load
      @chat ||= Chat.find_or_create(id: @chat_id)
      @chat
    end
  end
end
