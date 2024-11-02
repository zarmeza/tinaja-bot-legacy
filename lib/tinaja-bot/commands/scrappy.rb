# frozen_string_literal: true

require 'watir'

module TinajaBot
  module Commands
    module Scrappy
      BROWSER_ARGS = ['--headless', '--no-sandbox'].freeze
      BROWSER_URL = "http://#{ENV.fetch('BROWSER_HOSTNAME', nil)}:#{ENV.fetch('BROWSER_PORT', nil)}/webdriver".freeze

      def self.handler
        lambda do |event, *args|
          browser = Watir::Browser.new(:chrome, options: { args: BROWSER_ARGS }, url: BROWSER_URL)
          begin
            url = args&.join(' ')
            if url
              browser.goto url
              browser.screenshot.save 'screenshot.png'
              event.send_file File.open('screenshot.png', 'r')
            else
              event.respond "<@#{event.user.id}> gib url plz"
            end
          rescue Selenium::WebDriver::Error::UnknownError => e
            File.write('backtrace.txt', e.backtrace.join("\n"))
            event.respond "`#{e.detailed_message}`"
            event.send_file File.open('backtrace.txt', 'r')
          end
          nil
        end
      end
    end
  end
end
