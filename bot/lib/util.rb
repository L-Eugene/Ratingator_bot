module Bot::Util
  def self.next_day(str)
    x = Date.parse(str)
    y = x > Date.today ? 0 : 7
    x + y
  end
end