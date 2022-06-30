require "lib/common"

describe Bot::Util do
  before :each do
    Timecop.freeze("2022-06-27 18:00:00")
  end

  after :each do
    Timecop.return
  end

  %w(monday tuesday thursday wednesday friday saturday sunday).each do |elm|
    describe '#next_day', elm do
      subject { described_class.next_day(elm) }

      it { should be_a Date }
      it { should be > Date.today }
      it 'should be right day of week' do
        expect(subject.strftime("%A").downcase).to eq elm
      end
    end
  end
end