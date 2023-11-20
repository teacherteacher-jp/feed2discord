require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
  gem "feedjira"
end

feed_url = ENV["FEED_URL"]
webhook_url = ENV["WEBHOOK_URL"]

already_notified = File.read("already_notified.txt").split("\n")
feed = Feedjira.parse(Faraday.get(feed_url).body)
entries = feed.entries.sort_by(&:published)

exit if entries.empty?

p [entries.size, already_notified.size, entries.last.published]

entries.each do |entry|
  url = entry.url

  next if already_notified.include?(url)

  message = <<~MESSAGE
    :bell: 新着エピソード :bell:
    お聞きになったら、ぜひ感想をお寄せください
    #{url}
  MESSAGE

  puts message
  puts
  Faraday.post(webhook_url, { content: message })

  already_notified.push(url)
end

File.write("already_notified.txt", already_notified.join("\n"))
