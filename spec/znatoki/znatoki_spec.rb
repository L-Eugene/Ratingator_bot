require "znatoki"

YAML.load_file(File.join FIXTURES_PATH, 'znatoki', 'datasets.yml').each do |dataset|
  describe dataset[:description] do
    before :each do
      stub_request(:get, 'https://znatoki.info/forums/-/index.rss')
        .to_return(body: File.read(File.join FIXTURES_PATH, 'znatoki', dataset[:file]))
      dataset[:tournaments].each do |trnmt|
        stub_request(:get, "http://rating.chgk.info/api/tournaments/#{trnmt}")
          .to_return(body: File.read(File.join FIXTURES_PATH, 'znatoki', "tournament.#{trnmt}.json"))
      end
      Timecop.freeze("#{dataset[:date]} 12:00:00")
    end

    after :each do
      Timecop.return
    end

    dataset[:testcases].each do |testcase|
      it testcase[:description] do
        Timecop.freeze("#{testcase[:date]} 12:00:00") if testcase.key? :date
        data = get_poll_options
        eval testcase[:expectations]
      end
    end
  end
end
