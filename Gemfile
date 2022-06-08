%w(bot layer).each do |dir|
  eval(File.read("#{dir}/Gemfile"), nil, "#{dir}/Gemfile") if File.exists?("#{dir}/Gemfile")
end

source 'https://rubygems.org' do
  group :test do
    gem 'factory_bot'
    gem 'rake'
    gem 'rspec'
    gem 'rubocop'
    gem 'timecop'
    gem 'webmock'
  end
end