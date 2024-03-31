require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "faraday"
  gem "feedjira"
end

already_notified = File.read("already_notified.txt").split("\n")

config = ENV["CONFIG"]
config ||= File.read("config.tsv")

config.split("\n").map { _1.split("|||") }.map { _1.map(&:strip) }.each do |title, feed_url, webhook_url|
  puts "%s\n%s" % ["=" * 40, title]

  feed = Feedjira.parse(Faraday.get(feed_url).body)
  entries = feed.entries.sort_by(&:published)

  next if entries.empty?

  p [entries.size, already_notified.size, entries.last.published]

  entries.each do |entry|
    url = entry.url
    key = [feed_url, entry.entry_id].join("|||")

    next if already_notified.include?(key)

    message = <<~MESSAGE
      新着エピソードをキャッチしました！
      #{url}
    MESSAGE

    puts message
    puts
    Faraday.post(webhook_url, { content: message })

    already_notified.push(key)
  end
end

File.write("already_notified.txt", already_notified.sort.join("\n") + "\n")
