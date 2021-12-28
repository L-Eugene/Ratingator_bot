require 'aws-sdk-secretsmanager' if ENV.key? 'AWS_REGION'
require 'aws-sdk-dynamodb' if ENV.key? 'AWS_REGION'

require 'bundler'
Bundler.setup(:default)

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

def weekly(event:, context:)
  secret = telegram_token

  chat_list[:items].each do |chat|
    team = ChgkRating.client.team(chat['TeamID'].to_i)

    # Team rating changes
    ratings = {
      prev: team.ratings[-2],
      last: team.ratings[-1]
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
      "#{index + 1}. #{city_ratings[index].team.eager_load!.name} (#{city_ratings[index].rating})"
    end

    # Tournaments influenced last rating 
    tournaments = team.tournaments(season_id: 'last').select do |tournament|
      tournament.eager_load!
      tournament.date_end <= ratings[:last].date  && tournament.date_end > ratings[:prev].date
    end.map do |tournament|
      result = tournament.team_list.select { |item| item.team.id == team.id }.first

      [
        result.included_in_rating ? "#{result.diff_bonus} _(#{result.bonus_b})_" : 'unrated',
        "*[#{tournament.type_char}]*",
        "_\"#{tournament.name}\"_",
        "*место* #{result.position} #{ "(#{result.predicted_position})" if result.included_in_rating }",
        "*взято* #{result.questions_total}/#{tournament.questions_total}"
      ].join(' ')
    end

    # TODO: send stat to chat
    Telegram::Bot::Client.run(secret) do |bot| 
      bot.api.send_message(chat_id: chat['ChatID'].to_i, text: <<~MESSAGE, parse_mode: 'Markdown')
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
    end
  end
end
