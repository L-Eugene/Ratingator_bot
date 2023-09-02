# frozen_string_literal: true

require 'znatoki'

datasets = YAML.load_file(
  File.join(FIXTURES_PATH, 'znatoki', 'datasets.yml'),
  permitted_classes: [Date, Symbol]
)

datasets.each do |dataset|
  describe dataset[:description] do
    before :each do
      VCR.turn_off!
      WebMock.disable_net_connect!(allow_localhost: true)
      stub_request(:get, 'https://znatoki.info/forums/-/index.rss')
        .to_return(body: File.read(File.join(FIXTURES_PATH, 'znatoki', dataset[:file])))
      dataset[:tournaments].each do |trnmt|
        stub_request(:get, "https://api.rating.chgk.net/tournaments/#{trnmt}")
          .to_return(body: File.read(File.join(FIXTURES_PATH, 'znatoki', "tournament.#{trnmt}.json")))
      end
      Timecop.freeze("#{dataset[:date]} 12:00:00")
    end

    after :each do
      Timecop.return
      WebMock.allow_net_connect!
      VCR.turn_on!
    end

    dataset[:testcases].each do |testcase|
      it testcase[:description] do
        Timecop.freeze("#{testcase[:date]} 12:00:00") if testcase.key? :date
        # rubocop:disable Lint/UselessAssignment
        # This var is used in evaluated code
        data = poll_options
        # rubocop:enable Lint/UselessAssignment
        eval testcase[:expectations]
      end
    end
  end
end
