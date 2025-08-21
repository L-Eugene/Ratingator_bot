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
end
