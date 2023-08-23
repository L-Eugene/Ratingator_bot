# frozen_string_literal: true

require_relative 'common'

module RatingChgkV2
  module Models
    # loading team ratings from MAII
    class TeamModel
      def ratings
        @ratings ||= ratings_data
      end

      def rating(id)
        ratings.detect { |r| r.id == id }
      end

      private

      # Getting team ratings from MAII rating site
      def ratings_data
        JSON.parse(
          Faraday.get("https://rating.maii.li/api/v1/b/teams/#{id}/releases.json").body,
          object_class: OpenStruct
        ).items[0, 5]
      end
    end

    # loading tournament results
    class TeamTournamentModel
      def tournament
        @tournament ||= RatingChgkV2.client.tournament @idtournament
      end

      def result
        @result ||= tournament.results(includeRatingB: true).detect { |r| r.team['id'] == @idteam }
      end
    end
  end
end

# rubocop:disable Lint/UnusedMethodArgument
def weekly(event:, context:)
  input = JSON.parse(event['Records'].first['body'])

  team = RatingChgkV2.client.team(input['TeamID'])

  # Calculate latest release id
  rating_id = 1.step { |i| break i if DateTime.parse(team.ratings[-i].date) < DateTime.now }

  # Team rating changes
  ratings = {
    prev: team.ratings[rating_id + 1],
    last: team.ratings[rating_id]
  }

  delta = {
    rating: ratings[:last].rating - ratings[:prev].rating,
    position: ratings[:last].place - ratings[:prev].place
  }

  # Ratings inside city of base team
  city_ratings = RatingChgkV2.client.teams(town: team.town['id'], pagination: false).map do |cteam|
    obj = cteam.rating(ratings[:last].id)
    next nil if obj.rating.nil?

    obj.tap { |r| r.team = cteam }
  rescue StandardError
    nil
  end.compact.sort_by(&:rating).reverse

  city_position = city_ratings.find_index { |rating| rating.team.id == team.id }
  neighbours = Range.new([0, city_position - 1].max, [city_ratings.size - 1, city_position + 1].min).to_a.map do |index|
    bold = city_ratings[index].team.id == team.id ? '*' : ''
    "#{bold}#{index + 1}.#{bold} " \
      "[#{city_ratings[index].team.name}](https://rating.chgk.info/team/#{city_ratings[index].team.id}) " \
      "(#{city_ratings[index].rating})"
  end

  # Tournaments influenced last rating
  block_size = [team.tournaments.items.size, 30].min
  tournaments = team.tournaments(pagination: 'false')[-block_size, block_size].uniq(&:idtournament).select do |relation|
    Date.parse(relation.tournament.dateEnd).between?(
      Date.parse(team.ratings[rating_id + 3].date),
      Date.parse(ratings[:last].date)
    )
  end

  tournaments.map! do |relation|
    # Skip tournaments without colculated results
    next if relation.result.position.to_s == ''

    rating = OpenStruct.new(relation.result.rating)

    [
      "#{Bot::Util.surround(rating.d || 0,
                            !rating.inRating || !relation.tournament.tournamentInRatingBalanced)} _(#{rating.b})_",
      "*[#{Bot::Util.type_char(relation.tournament.type['name'])}]*",
      "[#{relation.tournament.name}](https://rating.chgk.info/tournament/#{relation.idtournament})",
      "*место* #{relation.result.position || '?'} #{"(#{rating.predictedPosition})" if rating.predictedPosition}",
      "*взято* #{relation.result.questionsTotal || '?'}/#{relation.tournament.questionQty.map { |_, v| v }.sum}"
    ].join(' ')
  end.compact!

  Telegram::Bot::Client.run(telegram_token) do |bot|
    message = <<~MESSAGE
      *Релиз рейтинга от #{ratings[:last].date}*

      *Рейтинг:* #{ratings[:last].rating} (#{Bot::Util.arrow(delta[:rating])})
      *Место:* #{Bot::Util.medal(ratings[:last].place)} (#{Bot::Util.arrow(-1 * delta[:position])})
      *В городе:* #{Bot::Util.medal(city_position + 1)}

      *Соседи по таблице (город):*#{' '}
      #{neighbours.join("\n")}

      *Последние учтенные турниры:*
      #{tournaments.join("\n")}

      #ratingator
    MESSAGE

    input['ChatList'].each { |chat| bot.api.send_message(chat_id: chat.to_i, text: message, parse_mode: 'Markdown') }
  end

  { statusCode: 200 }
end
# rubocop:enable Lint/UnusedMethodArgument

# rubocop:disable Lint/UnusedMethodArgument
# Filling the SQS queue with team list we want to track.
# Object should have TeamID and ChatList to send the result.
def initiate(event:, context:)
  require 'aws-sdk-sqs'
  team_chats = Bot::Chat.scan.each_with_object(Hash.new { |h, k| h[k] = [] }) do |chat, hash|
    hash[chat.team_id] << chat.id if chat.team_id
  end
  team_chats.each do |team, chats|
    sqs = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION', nil))
    sqs.send_message(queue_url: ENV.fetch('SQS_QUEUE_URL', nil),
                     message_body: { TeamID: team, ChatList: chats }.to_json)
    puts "Sent message: TeamID=#{team}, ChatList: #{chats.join ', '}"
  rescue StandardError => e
    puts "Error sending message: #{e.message}"
  end
end
# rubocop:enable Lint/UnusedMethodArgument
