require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
  gem "feedjira"
end

feed_url = ENV["FEED_URL"]
webhook_url = ENV["WEBHOOK_URL"]

feed = Feedjira.parse(Faraday.get(feed_url).body)

feed.entries.each do |entry|
  break if entry.published < (Time.now - 15 * 60)

  message = <<~MESSAGE
    :bell: 新着エピソード :bell:
    お聞きになったら、ぜひ感想をお寄せください
    #{entry.url}
  MESSAGE

  puts message
  Faraday.post(webhook_url, { content: message })
end
