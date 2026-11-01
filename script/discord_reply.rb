#!/usr/bin/env ruby
# frozen_string_literal: true

# Interactive prompt that posts as the bot: ask for a channel once, then keep
# asking for a message id and a text until you quit.
#
#   bundle exec ruby script/discord_reply.rb [CHANNEL_ID]
#
# Reads DISCORD_BOT_TOKEN from the environment, falling back to the .env at the
# repository root. DISCORD_API_BASE exists so the loop can be pointed at a stub
# instead of Discord.
#
# Prompts use plain gets on purpose. readline and reline are both bundled gems
# in Ruby 4.0 and neither is declared in this Gemfile, so `bundle exec` cannot
# load them; probing for them only prints a warning. `gem 'reline'` in the
# Gemfile is the switch that would buy back editing and history.

require 'dotenv'
require 'json'
require 'net/http'
require 'uri'

Dotenv.load(File.expand_path('../.env', __dir__))

module DiscordReply
  API = ENV.fetch('DISCORD_API_BASE', 'https://discord.com/api/v10')
  USER_AGENT = 'tinaja-bot (https://github.com/zarmeza/tinaja-bot)'
  QUIT = %w[q quit exit].freeze
  ID_PATTERN = /\A\d+\z/
  MESSAGE_PROMPT = 'Message id (blank = plain message, c = change channel, q = quit): '

  class ApiError < StandardError; end

  def self.call(token, channel_id = nil)
    channel = channel_id ? try_channel(token, channel_id) : nil
    channel ||= ask_channel(token)
    channel = ask_message(token, channel) while channel
  rescue Interrupt
    puts
  end

  def self.ask_channel(token)
    loop do
      id = prompt('Channel id: ')
      return nil if id.nil? || QUIT.include?(id)

      channel = try_channel(token, id) if id.match?(ID_PATTERN)
      return channel if channel
    end
  end

  def self.try_channel(token, id)
    channel = api(:get, "/channels/#{id}", token)
    puts "  ##{channel['name']}"
    channel
  rescue ApiError => e
    puts "  #{e.message}"
    nil
  end

  # Returns the channel to keep using, or nil to quit.
  def self.ask_message(token, channel)
    id = prompt(MESSAGE_PROMPT)
    return nil if id.nil? || QUIT.include?(id)
    return ask_channel(token) if id == 'c'
    return reject(id, channel) unless okay_target?(id)

    send_text(token, channel, id.empty? ? nil : id)
    channel
  rescue ApiError => e
    puts "  #{e.message}"
    channel
  end

  def self.reject(id, channel)
    puts "  #{id} is not a message id"
    channel
  end

  def self.okay_target?(id)
    id.empty? || id.match?(ID_PATTERN)
  end

  def self.send_text(token, channel, reply_to)
    text = prompt('Text: ')
    return if text.nil? || text.empty?

    message = post(token, channel, text, reply_to)
    puts "  -> #{link(message)}"
  end

  def self.post(token, channel, text, reply_to)
    body = { content: text, allowed_mentions: { replied_user: false } }
    body[:message_reference] = { message_id: reply_to } if reply_to
    api(:post, "/channels/#{channel['id']}/messages", token, body)
  end

  def self.api(method, path, token, body = nil)
    uri = URI("#{API}#{path}")
    req = (method == :get ? Net::HTTP::Get : Net::HTTP::Post).new(uri, headers(token))
    req.body = body.to_json if body
    JSON.parse(fetch(req, uri))
  end

  def self.fetch(req, uri)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
    raise ApiError, "#{res.code} #{reason(res)}" unless res.is_a?(Net::HTTPSuccess)

    res.body
  end

  def self.headers(token)
    { 'Authorization' => "Bot #{token}", 'Content-Type' => 'application/json', 'User-Agent' => USER_AGENT }
  end

  def self.reason(response)
    JSON.parse(response.body)['message'] || response.message
  rescue JSON::ParserError, TypeError
    response.message
  end

  def self.link(message)
    "https://discord.com/channels/#{message['guild_id']}/#{message['channel_id']}/#{message['id']}"
  end

  def self.prompt(text)
    print text
    $stdin.gets&.strip
  end
end

token = ENV['DISCORD_BOT_TOKEN'].to_s.strip
abort 'DISCORD_BOT_TOKEN is not set (environment or .env)' if token.empty?

DiscordReply.call(token, ARGV.first)
