# frozen_string_literal: true

require 'venues'

describe Bot::Command::PollFromMessage do
    describe '#match?' do
        it 'should match message with 3+ options' do
            message = instance_double('Telegram::Bot::Types::Message', text: <<~TEXT)
                [6.5] Option 1
                [7] Option 2
                [8] Option 3
            TEXT

            expect(described_class.match?(message)).to be true
        end

        it 'should not match message with 2 options' do
            message = instance_double('Telegram::Bot::Types::Message', text: <<~TEXT)
                [6.5] Option 1
                [7] Option 2
            TEXT

            expect(described_class.match?(message)).to be false
        end

        it 'should not match message without options' do
            message = instance_double('Telegram::Bot::Types::Message', text: <<~TEXT)
                Option 1
                Option 2
                Option 3
            TEXT

            expect(described_class.match?(message)).to be false
        end

        it 'should not match message witout text' do
            message = instance_double('Telegram::Bot::Types::Message', text: nil)

            expect(described_class.match?(message)).to be false
        end
    end

    describe '#process' do
        before :each do
            ENV['TELEGRAM_TOKEN'] = 'fake_token'

            @chat = instance_double('Chat')
            allow(@chat).to receive(:id).and_return(123)
            allow(@chat).to receive(:extra_poll_options).and_return(['Extra Option 1', 'Extra Option 2'])

            telegram = instance_double('Telegram::Bot::Client')
            allow(Telegram::Bot::Client).to receive(:new).and_return(telegram)

            @api_double = double('Telegram::Bot::Api')
            allow(telegram).to receive(:api).and_return(@api_double)
        end

        it 'should send poll with options' do
            message = instance_double('Telegram::Bot::Types::Message', message_id: 1, text: <<~TEXT)
                [6.5] Option 1
                [7] Option 2
                [8] Option 3
            TEXT

            expect(@api_double).to receive(:send_poll).with(
                chat_id: 123,
                question: 'Выберите варианты:',
                reply_to_message_id: 1,
                options: [
                    '[6.5] Option 1',
                    '[7] Option 2',
                    '[8] Option 3',
                    'Extra Option 1',
                    'Extra Option 2'
                ],
                is_anonymous: false,
                allows_multiple_answers: true
            ).and_return(true)

            described_class.process(@chat, message)
        end

        it 'should split options into several polls if more than 10' do
            message = instance_double('Telegram::Bot::Types::Message', message_id: 1, text: <<~TEXT)
                [6.5] Option 1
                [7] Option 2
                [8] Option 3
                [8] Option 4
                [8] Option 5
                [8] Option 6
                [8] Option 7
                [8] Option 8
                [8] Option 9
                [8] Option 10
                [8] Option 11
            TEXT

            expect(@api_double).to receive(:send_poll).with(
                chat_id: 123,
                question: 'Выберите варианты:',
                reply_to_message_id: 1,
                options: [
                    '[6.5] Option 1',
                    '[7] Option 2',
                    '[8] Option 3',
                    '[8] Option 4',
                    '[8] Option 5',
                    '[8] Option 6',
                    '[8] Option 7',
                    '[8] Option 8',
                    'Extra Option 1',
                    'Extra Option 2'
                ],
                is_anonymous: false,
                allows_multiple_answers: true
            ).and_return(true)

            expect(@api_double).to receive(:send_poll).with(
                chat_id: 123,
                question: 'Выберите варианты:',
                reply_to_message_id: 1,
                options: [
                    '[8] Option 9',
                    '[8] Option 10',
                    '[8] Option 11',
                    'Extra Option 1',
                    'Extra Option 2'
                ],
                is_anonymous: false,
                allows_multiple_answers: true
            ).and_return(true)

            described_class.process(@chat, message)
        end
    end
end
