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
    key = [feed_url, entry.entry_id].join("|||")

    next if already_notified.include?(key)

    puts "新着！ #{entry.title} #{entry.url}"

    content = "新着エピソードをキャッチしました！"
    embeds = [{
      author: { name: feed.title, url: feed.url },
      title: entry.title,
      url: entry.url,
      thumbnail: { url: entry.image || feed.image&.url },
      timestamp: entry.published.iso8601,
    }]
    Faraday.post(webhook_url, { content:, embeds: }.to_json, "Content-Type" => "application/json")

    sleep 2

    already_notified.push(key)
    File.write("already_notified.txt", already_notified.sort.join("\n") + "\n")
  end
end
