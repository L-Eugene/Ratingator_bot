require "venues"

describe VenueWatch do
  before :each do
    stub_request(:get, 'http://api.rating.chgk.net/docs.json')
      .to_return(body: File.read(File.join FIXTURES_PATH, 'venues', 'docs.json'))

    # Freeze time to make requests reproducible
    Timecop.freeze("2022-06-24 12:00:00")

    # response with empty dataset: venue id=3562
    # response with single tournament: venue id=3563
    # response with multiple tournaments: venue id=3564
    [3562, 3563, 3564].each do |venue_id|
      stub_request(:get, "http://api.rating.chgk.net/venues/#{venue_id}/requests")
        .with(query: {
          'dateStart[strictly_after]': '2022-06-24',
          'dateStart[strictly_before]': '2022-06-25',
          itemsPerPage: 50,
          page: 1,
          pagination: true
        })
        .to_return(
          body: File.read(File.join FIXTURES_PATH, 'venues', "venue_requests_#{venue_id}.json"),
          headers: { content_type: 'application/ld+json; charset=utf-8' }
        )
    end

    [7806, 7967, 7976].each do |tournament_id|
      stub_request(:get, "http://api.rating.chgk.net/tournaments/#{tournament_id}")
        .to_return(
          body: File.read(File.join FIXTURES_PATH, 'venues', "tournament_#{tournament_id}.json"),
          headers: { content_type: 'application/ld+json; charset=utf-8' }
        )
    end

    VenueWatch.reset_cache!
  end

  after :each do
    Timecop.return
  end

  context 'no tournaments registered' do
    let(:result) { VenueWatch[3562] }

    it 'should get empty set if no tournaments registered' do
      expect(result.events).to be_empty
    end
  end

  context 'single tournament registered' do
    let(:result) { VenueWatch[3563] }

    it 'should get valid data for single tournament' do
      expect(result.events.size).to eq 1

      expect(result.events.first[:tournament].name).to eq 'Delivery Cup Май (синхрон)'
      expect(result.events.first[:beginning]).to eq DateTime.parse("2022-05-08 12:00 GMT+3")

      expect(WebMock).to have_requested(:get, 'http://api.rating.chgk.net/tournaments/7967').once
    end
  end

  context 'two tournaments registered' do
    let(:result) { VenueWatch[3564] }

    it 'should get valid data for two tournaments' do
      expect(result.events.size).to eq 2

      expect(WebMock).to have_requested(:get, 'http://api.rating.chgk.net/tournaments/7976').once
      expect(WebMock).to have_requested(:get, 'http://api.rating.chgk.net/tournaments/7806').once
    end

    it 'should sort tournaments by beginning time' do
      expect(result.events.first[:tournament].name).to eq 'Geek. The Last of'
      expect(result.events.first[:beginning]).to eq DateTime.parse("2022-06-19 12:00 GMT+3")
      expect(result.events.last[:tournament].name).to eq 'Бесконечные Земли. Том XXVII (синхрон)'
      expect(result.events.last[:beginning]).to eq DateTime.parse("2022-06-19 14:00 GMT+3")
    end
  end
end