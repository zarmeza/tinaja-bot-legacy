# frozen_string_literal: true

require 'httparty'

module TinajaBot
  module Commands
    module Exercism
      def self.handler
        lambda do |event, profile_name = nil|
          if profile_name
            response = HTTParty.get "https://exercism.org/profiles/#{profile_name}"
            event.respond get_response_message(response, profile_name)
          else
            event.respond "<@#{event.user.id}> you must provide an exercism profile name."
          end

          nil
        end
      end

      def self.get_response_message(response, profile_name)
        case response.code
        when 200..299
          response.request.uri
        when 400..499
          "*#{profile_name}* does not appear to be a valid exercism public profile"
        else
          "Unexpected error: (HTTP #{response.code})"
        end
      end
    end
  end
end
