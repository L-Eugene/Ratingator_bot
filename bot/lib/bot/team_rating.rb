# frozen_string_literal: true

module Bot
  # Class to build rating statistic for team
  class TeamRating
    attr_reader :current_rating_id, :previous_rating_id

    def initialize(team)
      @team = team

      @current_rating_id = 1.step { |i| break i if DateTime.parse(@team.ratings[-i].date) < DateTime.now }
      @previous_rating_id = @current_rating_id + 1

      @ratings = {
        prev: @team.ratings[@previous_rating_id],
        last: @team.ratings[@current_rating_id]
      }
    end

    def message
      <<~MESSAGE
        *Релиз рейтинга от #{@ratings[:last].date}*

        *Рейтинг:* #{@ratings[:last].rating} (#{Bot::Util.arrow(delta[:rating])})
        *Место:* #{Bot::Util.medal(@ratings[:last].place)} (#{Bot::Util.arrow(-1 * delta[:position])})
        *В городе:* #{Bot::Util.medal(city_position + 1)}

        *Соседи по таблице (город):*
        #{city_neighbours.join("\n")}

        *Последние учтенные турниры:*
        #{affected_by.join("\n")}

        #ratingator
      MESSAGE
    end

    private

    def delta
      {
        rating: @ratings[:last].rating - @ratings[:prev].rating,
        position: @ratings[:last].place - @ratings[:prev].place
      }
    end

    # Get all teams from the city team belongs to with active rating
    def city_ratings
      @city_ratings ||= RatingChgkV2.client.teams(town: @team.town['id'], pagination: false).map do |cteam|
        record = cteam.rating(@ratings[:last].id)
        next nil if record.rating.nil?

        record.team = OpenStruct.new(id: cteam.id, name: cteam.name)

        record
      rescue StandardError
        nil
      end.compact.sort_by(&:rating).reverse
    end

    def city_position
      @city_position ||= city_ratings.find_index { |rating| rating.team.id == @team.id }
    end

    # Get neighbours in city rating standings
    def city_neighbours
      # Get neighbours up and down if any
      display_range = Range.new(
        [0, city_position - 1].max,
        [city_ratings.size - 1, city_position + 1].min
      )

      display_range.to_a.map do |index|
        # Make bold if this line is for current team
        bold = city_ratings[index].team.id == @team.id ? '*' : ''

        team_url = "[#{city_ratings[index].team.name}](https://rating.chgk.info/teams/#{city_ratings[index].team.id})"

        "#{bold}#{index + 1}.#{bold} #{team_url} (#{city_ratings[index].rating})"
      end
    end

    def affected_by
      # Tournaments influenced last rating
      block_size = [@team.tournaments.items.size, 30].min

      @team.tournaments(pagination: 'false')[-block_size, block_size].uniq(&:idtournament).select do |relation|
        Date.parse(relation.tournament.dateEnd).between?(
          Date.parse(@team.ratings[@current_rating_id + 3].date),
          Date.parse(@ratings[:last].date)
        )
      end.map do |relation|
        # Skip tournaments without calculated results
        next if relation.result.position.to_s == ''

        rating = OpenStruct.new(relation.result.rating)

        # team rating is surrounded by brackets if tournament is not rated
        team_rating = Bot::Util.surround(rating.d || 0,
                                         !rating.inRating || !relation.tournament.tournamentInRatingBalanced)

        # Type of tournament human-readable
        tournament_char = Bot::Util.type_char(relation.tournament.type['name'])

        tournament_url = "[#{relation.tournament.name}](https://rating.chgk.info/tournament/#{relation.idtournament})"

        team_position = relation.result.position || '?'
        team_predicted = rating.predictedPosition ? "(#{rating.predictedPosition})" : ''

        team_questions = relation.result.questionsTotal || '?'
        tournament_questions = relation.tournament.questionQty.map { |_, v| v }.sum

        "#{team_rating} _(#{rating.b})_ *[#{tournament_char}]* #{tournament_url} " \
          "*место* #{team_position} #{team_predicted} *взято* #{team_questions}/#{tournament_questions}"
      end.compact
    end
  end
end
