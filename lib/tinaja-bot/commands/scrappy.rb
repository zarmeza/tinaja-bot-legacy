# frozen_string_literal: true

require 'socket'
require 'watir'

module TinajaBot
  module Commands
    module Scrappy
      BROWSER_ARGS = ['--headless', '--no-sandbox'].freeze
      BROWSER_URL = "http://#{ENV.fetch('BROWSER_HOSTNAME', nil)}:#{ENV.fetch('BROWSER_PORT', nil)}/webdriver".freeze
      # The bot and Chrome are sibling containers that start at the same time, so
      # a !scrappy issued in the first seconds can arrive before the WebDriver
      # port is accepting connections.
      BROWSER_READY_TIMEOUT = 20
      BROWSER_POLL_INTERVAL = 2

      def self.handler
        lambda do |event, *args|
          url = args&.join(' ')
          if url && !url.empty?
            capture_and_send(event, url)
          else
            event.respond "<@#{event.user.id}> gib url plz"
          end
          nil
        end
      end

      def self.capture_and_send(event, url)
        return event.respond(starting_up_message(event)) unless wait_for_browser

        browser = Watir::Browser.new(:chrome, options: { args: BROWSER_ARGS }, url: BROWSER_URL)
        browser.goto url
        browser.screenshot.save 'screenshot.png'
        event.send_file File.open('screenshot.png', 'r')
      rescue Selenium::WebDriver::Error::UnknownError => e
        handle_error(event, e)
      end

      def self.wait_for_browser
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + BROWSER_READY_TIMEOUT

        loop do
          return true if browser_ready?
          return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep BROWSER_POLL_INTERVAL
        end
      end

      def self.browser_ready?
        TCPSocket.new(ENV.fetch('BROWSER_HOSTNAME', nil), ENV.fetch('BROWSER_PORT', nil)).close
        true
      rescue StandardError
        false
      end

      def self.starting_up_message(event)
        "<@#{event.user.id}> chrome is still booting, give it a sec and try again"
      end

      def self.handle_error(event, error)
        File.write('backtrace.txt', error.backtrace.join("\n"))
        event.respond "`#{error.detailed_message}`"
        event.send_file File.open('backtrace.txt', 'r')
      end
    end
  end
end
