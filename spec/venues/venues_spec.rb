# frozen_string_literal: true

require 'venues'

describe VenueWatch do
  before :each do
    # Freeze time to make requests reproducible
    Timecop.freeze('2022-06-26 12:00:00')

    VenueWatch.reset_cache!
  end

  after :each do
    Timecop.return
  end

  context 'no tournaments registered' do
    let(:result) do
      VCR.use_cassette('venues/3562') { VenueWatch[3562] }
    end

    it 'should get empty set if no tournaments registered' do
      VCR.use_cassette('venues/no_tournaments') { expect(result.events).to be_empty }
    end
  end

  context 'single tournament registered' do
    let(:result) do
      VCR.use_cassette('venues/4588') { VenueWatch[4588] }
    end

    it 'should get valid data for single tournament' do
      VCR.use_cassette('venues/one_tournament') do
        expect(result.events.size).to eq 1

        expect(result.events.first[:tournament].name).to eq 'Лето в Тюмени. Божоле Нуво'
        expect(result.events.first[:beginning]).to eq DateTime.parse('2022-06-26 17:00 GMT+3')
      end
    end
  end

  context 'two tournaments registered' do
    let(:result) do
      VCR.use_cassette('venues/3563') { VenueWatch[3563] }
    end

    it 'should sort tournaments by beginning time' do
      VCR.use_cassette('venues/two_tournaments') do
        expect(result.events.size).to eq 2

        expect(result.events.map { |x| x[:tournament].id }).to match_array [8141, 7589]

        expect(result.events.first[:tournament].name).to eq 'Лето в Тюмени. Божоле Нуво'
        expect(result.events.first[:beginning]).to eq DateTime.parse('2022-06-26 12:00 GMT+3')
        expect(result.events.last[:tournament].name).to eq 'Скрулл Кап. Третий этап (синхрон)'
        expect(result.events.last[:beginning]).to eq DateTime.parse('2022-06-26 14:00 GMT+3')
      end
    end
  end

  context 'two requests, one cancelled' do
    let(:result) do
      VCR.use_cassette('venues/3564') { VenueWatch[3564] }
    end

    it 'should sort tournaments by beginning time' do
      VCR.use_cassette('venues/two_tournaments') do
        expect(result.events.size).to eq 1

        expect(result.events.map { |x| x[:tournament].id }).to match_array [8141]

        expect(result.events.first[:tournament].name).to eq 'Лето в Тюмени. Божоле Нуво'
        expect(result.events.first[:beginning]).to eq DateTime.parse('2022-06-26 12:00 GMT+3')
      end
    end
  end
end
