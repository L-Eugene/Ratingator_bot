# frozen_string_literal: true

require 'common'

describe Bot::Util do
  before :each do
    Timecop.freeze('2022-06-27 18:00:00')
  end

  after :each do
    Timecop.return
  end

  %w[monday tuesday thursday wednesday friday saturday sunday].each do |elm|
    describe '#next_day', elm do
      subject { described_class.next_day(elm) }

      it { should be_a Date }
      it { should be > Date.today }
      it 'should be right day of week' do
        expect(subject.strftime('%A').downcase).to eq elm
      end
    end
  end

  describe '#arrow' do
    it 'should return up arrow for positive value' do
      expect(subject.arrow(10)).to include '⬆'
    end

    it 'should return down arrow for negative value' do
      expect(subject.arrow(-10)).to include '⬇'
    end

    it 'should return right arrow for zero' do
      expect(subject.arrow(0)).to include '➡'
    end
  end

  describe '#medal' do
    let(:gold) { '🥇' }
    let(:silver) { '🥈' }
    let(:bronze) { '🥉' }
    let(:bullet) { '🔸' }

    it 'should return gold medal for first place' do
      expect(subject.medal(1)).to include gold
    end

    it 'should return silver medal for second place' do
      expect(subject.medal(2)).to include silver
    end

    it 'should return bronze medal for third place' do
      expect(subject.medal(3)).to include bronze
    end

    it 'should return bullet for all places except 1-3' do
      [-1, 0, 4, 10, 150].each { |x| expect(subject.medal(x)).to include bullet }
    end
  end

  describe '#surround' do
    let(:string) { 'test' }

    it 'should surround for positive' do
      expect(subject.surround(string, true)).to eq "\\[#{string}]"
    end

    it 'shouldn\'t surround for negative' do
      expect(subject.surround(string, false)).to eq string
    end
  end

  describe '#next_sunday' do
    it 'should return next sunday' do
      expect(subject.next_sunday(Date.parse('2025-08-21'))).to eq Date.parse('2025-08-24')
    end

    it 'should return next sunday if today is sunday' do
      expect(subject.next_sunday(Date.parse('2025-08-31'))).to eq Date.parse('2025-09-07')
    end
  end

  describe '#datetime_timezone_new_offset' do
    let(:utc_dt) { DateTime.parse('2022-06-27T12:00:00+00:00') }

    it 'should return a DateTime' do
      expect(subject.datetime_timezone_new_offset('Europe/Moscow', utc_dt)).to be_a DateTime
    end

    it 'should apply Moscow offset (+03:00)' do
      result = subject.datetime_timezone_new_offset('Europe/Moscow', utc_dt)
      expect(result.offset).to eq Rational(3, 24)
    end

    it 'should represent the same instant in time' do
      result = subject.datetime_timezone_new_offset('Europe/Moscow', utc_dt)
      expect(result.new_offset(0)).to eq utc_dt.new_offset(0)
    end

    it 'should apply UTC offset for Etc/UTC' do
      result = subject.datetime_timezone_new_offset('Etc/UTC', utc_dt)
      expect(result.offset).to eq 0
    end

    it 'should apply summer time (DST) offset for Europe/Berlin in June (+02:00)' do
      result = subject.datetime_timezone_new_offset('Europe/Berlin', utc_dt)
      expect(result.offset).to eq Rational(2, 24)
    end

    it 'should apply winter time offset for Europe/Berlin in January (+01:00)' do
      winter_dt = DateTime.parse('2022-01-15T12:00:00+00:00')
      result = subject.datetime_timezone_new_offset('Europe/Berlin', winter_dt)
      expect(result.offset).to eq Rational(1, 24)
    end

    it 'should apply negative offset for America/New_York in June (-04:00 DST)' do
      result = subject.datetime_timezone_new_offset('America/New_York', utc_dt)
      expect(result.offset).to eq Rational(-4, 24)
    end

    it 'should default to DateTime.now when dt is not provided' do
      result = subject.datetime_timezone_new_offset('Europe/Moscow')
      expect(result).to be_a DateTime
      expect(result.offset).to eq Rational(3, 24)
    end

    it 'should raise error for invalid timezone name' do
      expect { subject.datetime_timezone_new_offset('Invalid/Timezone', utc_dt) }
        .to raise_error(TZInfo::InvalidTimezoneIdentifier)
    end
  end
end
