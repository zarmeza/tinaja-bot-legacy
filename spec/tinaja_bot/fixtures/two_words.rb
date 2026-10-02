# frozen_string_literal: true

module TinajaBot
  module Commands
    # Fixture for the loader spec: it proves that a snake_case command filename
    # resolves to its CamelCase handler module. Not a shipped command.
    module TwoWords
      def self.handler
        lambda do |event|
          event.respond 'two words'
          nil
        end
      end
    end
  end
end
