require_relative 'lib/common.rb'

require 'telegram/bot'
require 'chgk_rating'
require 'json'

def arrow(number)
  char = case number
         when :zero?.to_proc
           '➡️'
         when :positive?.to_proc
           '⬆️'
         else
           '⬇️'
         end

  "#{char} #{number.abs}"
end

def medal(number)
  values = ['🔸', '🥇', '🥈', '🥉']
  char = values.first
  char = values[number.to_i] if values.size > number.to_i

  "#{char} #{number}"
end

# Surround string with brackets if condition is true
def surround(string, condition)
  condition ? "\\[#{string}]" : string
end

def type_char(tournament_type)
  case tournament_type
  when 'Асинхрон'
    'А'
  when 'Синхрон'
    'С'
  when 'Обычный'
    'Т'
  else
    '?'
  end
end

def weekly(event:, context:)
  input = JSON.parse(event["Records"].first["body"])

  team = ChgkRating.client.team(input['TeamID'])

  # Calculate latest release id
  rating_id = 1.step {|i| break i if team.ratings[-i].date < DateTime.now } * -1

  # Team rating changes
  ratings = {
    prev: team.ratings[rating_id - 1],
    last: team.ratings[rating_id]
  }

  delta = {
    rating: ratings[:last].rating - ratings[:prev].rating,
    position: ratings[:last].rating_position - ratings[:prev].rating_position
  }

  # Ratings inside city of base team
  city_ratings = ChgkRating.client.search_teams(town: team.town).map do |cteam|
    cteam.rating(ratings[:last].release_id)
  rescue
    nil
  end.compact.sort_by(&:rating).reverse

  city_position = city_ratings.find_index { |rating| rating.team.id == team.id  }
  neighbours = Range.new([0, city_position - 1].max, [city_ratings.size - 1, city_position + 1].min).to_a.map do |index|
    city_ratings[index].team.eager_load!
    bold = city_ratings[index].team.id == team.id ? '*' : ''
    "#{bold}#{index + 1}.#{bold} [#{city_ratings[index].team.name}](https://rating.chgk.info/team/#{city_ratings[index].team.id}) (#{city_ratings[index].rating})"
  end

  # Tournaments influenced last rating 
  tournaments = team.tournaments(season_id: 'last').select do |tournament|
    tournament.eager_load!
    tournament.date_end <= ratings[:last].date  && tournament.date_end > team.ratings[rating_id - 3].date
  end.map do |tournament|
    result = tournament.team_list.select { |item| item.team.id == team.id }.first

    # Skip tournaments without colculated results
    next if result.position.to_s == ''

    # rating only changed if at least 4 players from base took part in tournament
    is_base = ChgkRating.client.team_players_at_tournament(tournament.id, team.id).count(&:is_base) >= 4

    [
      "#{surround(result.diff_bonus || 0, !is_base || !tournament.tournament_in_rating)} _(#{result.bonus_b})_",
      "*[#{type_char(tournament.type_name)}]*",
      "[#{tournament.name}](https://rating.chgk.info/tournament/#{tournament.id})",
      "*место* #{result.position || '?'} #{ "(#{result.predicted_position})" if result.predicted_position }",
      "*взято* #{result.questions_total || '?'}/#{tournament.questions_total}"
    ].join(' ')
  end.compact

  Telegram::Bot::Client.run(telegram_token) do |bot|
    message = <<~MESSAGE
      *Релиз рейтинга от #{ratings[:last].date}*

      *Рейтинг:* #{ratings[:last].rating} (#{arrow(delta[:rating])})
      *Место:* #{medal(ratings[:last].rating_position)} (#{arrow(-1 * delta[:position])})
      *В городе:* #{medal(city_position + 1)}

      *Соседи по таблице (город):* 
      #{neighbours.join("\n")}

      *Последние учтенные турниры:*
      #{tournaments.join("\n")}

      \#ratingator
    MESSAGE

    input['ChatList'].each { |chat| bot.api.send_message(chat_id: chat.to_i, text: message, parse_mode: 'Markdown') }
  end

  { statusCode: 200 }
end

# Filling the SQS queue with team list we want to track.
# Object should have TeamID and ChatList to send the result.
def initiate(event:, context:)
  require 'aws-sdk-sqs'
  Bot::Chat.scan.inject(Hash.new { |h, k| h[k] = [] }) do |hash, chat|
    hash[chat.team_id] << chat.id if chat.team_id 
    hash
  end.each do |team, chats|
    sqs = Aws::SQS::Client.new(region: ENV['AWS_REGION'])
    sqs.send_message(queue_url: ENV['SQS_QUEUE_URL'], message_body: { TeamID: team, ChatList: chats }.to_json)
    puts "Sent message: TeamID=#{team}, ChatList: #{chats.join ', '}"
  rescue StandardError => e
    puts "Error sending message: #{e.message}"
  end
end
