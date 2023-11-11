require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
  gem "feedjira"
end

feed_url = ENV["FEED_URL"]
webhook_url = ENV["WEBHOOK_URL"]

last_successed_at = ARGV.shift
last_successed_at = last_successed_at.nil? ? Time.now : Time.parse(last_successed_at)

feed = Feedjira.parse(Faraday.get(feed_url).body)
entries = feed.entries.sort_by(&:published).reverse

exit if entries.empty?

p [entries.size, last_successed_at, entries.first.published]

entries.each do |entry|
  break if entry.published < last_successed_at

  message = <<~MESSAGE
    :bell: 新着エピソード :bell:
    お聞きになったら、ぜひ感想をお寄せください
    #{entry.url}
  MESSAGE

  puts message
  Faraday.post(webhook_url, { content: message })
end
