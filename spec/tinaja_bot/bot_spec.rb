# frozen_string_literal: true

RSpec.describe TinajaBot::Bot do
  # Must match the glob Bot#load_commands builds, so expand it: an unresolved
  # "spec/../lib" would be a different string and the stub would never match.
  let(:commands_glob) { File.expand_path('../../lib/tinaja-bot/commands/*.rb', __dir__) }
  let(:gateway) { instance_double(Discordrb::Commands::CommandBot, command: nil) }
  let(:bot) { described_class.new(token: 'a-token', client_id: 'a-client-id') }

  before do
    allow(Discordrb::Commands::CommandBot).to receive(:new).and_return(gateway)
  end

  describe 'command registration' do
    it 'points commands_glob at the real command directory' do
      # Guards the stub below: if this path drifts, Dir[] silently falls through
      # to the original and the multi-word example fails for the wrong reason.
      expect(Dir[commands_glob]).to include(a_string_ending_with('unexpo.rb'))
    end

    it 'registers every command file under its filename' do
      bot

      aggregate_failures do
        expect(gateway).to have_received(:command).with(:unexpo)
        expect(gateway).to have_received(:command).with(:exercism)
        expect(gateway).to have_received(:command).with(:scrappy)
      end
    end

    context 'when a command file has a multi-word name' do
      let(:fixture) { File.expand_path('fixtures/two_words.rb', __dir__) }

      before do
        allow(Dir).to receive(:[]).and_call_original
        allow(Dir).to receive(:[]).with(commands_glob).and_return([fixture])
      end

      it 'resolves the CamelCase module and registers the snake_case command' do
        bot

        aggregate_failures do
          expect(gateway).to have_received(:command).with(:two_words)
          expect(TinajaBot::Commands::TwoWords).to be_a(Module)
        end
      end
    end
  end

  describe '#module_name' do
    it 'capitalizes a single-word command name' do
      expect(bot.send(:module_name, :scrappy)).to eq('Scrappy')
    end

    it 'camelizes a multi-word command name' do
      expect(bot.send(:module_name, :two_words)).to eq('TwoWords')
    end

    it 'camelizes deeply multi-word command names' do
      expect(bot.send(:module_name, :a_b_c_d)).to eq('ABCD')
    end
  end
end
