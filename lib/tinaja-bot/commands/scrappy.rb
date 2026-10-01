# frozen_string_literal: true

require 'watir'

module TinajaBot
  module Commands
    module Scrappy
      BROWSER_ARGS = ['--headless', '--no-sandbox'].freeze
      BROWSER_URL = "http://#{ENV.fetch('BROWSER_HOSTNAME', nil)}:#{ENV.fetch('BROWSER_PORT', nil)}/webdriver".freeze

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
        browser = Watir::Browser.new(:chrome, options: { args: BROWSER_ARGS }, url: BROWSER_URL)
        browser.goto url
        browser.screenshot.save 'screenshot.png'
        event.send_file File.open('screenshot.png', 'r')
      rescue Selenium::WebDriver::Error::UnknownError => e
        handle_error(event, e)
      end

      def self.handle_error(event, error)
        File.write('backtrace.txt', error.backtrace.join("\n"))
        event.respond "`#{error.detailed_message}`"
        event.send_file File.open('backtrace.txt', 'r')
      end
    end
  end
end
