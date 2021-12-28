require 'scorpio'

class ChgkRating
  def initialize
    @rating_doc = Scorpio::OpenAPI::Document.from_instance(JSON.parse(Faraday.get('http://api.rating.chgk.net/docs.json').body))
    @rating_doc.base_url = 'http://api.rating.chgk.net/'
  end

  def method_missing(method_name, *args, &block)
    return @rating_doc.operations[method_name.to_s].run(*args) if operations.include? method_name.to_s
    super
  end

  def respond_to_missing?(method_name, include_private = false)
    operations.include? method_name.to_s
  end

  def operations
    @rating_doc.operations.map(&:operationId)
  end
end
