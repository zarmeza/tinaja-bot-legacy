# frozen_string_literal: true

require 'tinaja-bot/commands/exercism'

RSpec.describe TinajaBot::Commands::Exercism do
  let(:event) { FakeEvent.new(user_id: 7) }
  let(:profile_uri) { 'https://exercism.org/profiles/zarmeza' }

  def stub_response(code)
    response = instance_double(
      HTTParty::Response,
      code: code,
      request: instance_double(HTTParty::Request, uri: profile_uri)
    )
    allow(HTTParty).to receive(:get).and_return(response)
  end

  context 'without a profile name' do
    before { allow(HTTParty).to receive(:get) }

    it 'asks the user for one' do
      described_class.handler.call(event)

      expect(event.responses).to contain_exactly('<@7> you must provide an exercism profile name.')
    end

    it 'does not hit the API' do
      described_class.handler.call(event)

      expect(HTTParty).not_to have_received(:get)
    end
  end

  context 'with a profile name' do
    before { allow(HTTParty).to receive(:get).and_call_original }

    it 'requests the public profile URL for that name' do
      stub_response(200)

      described_class.handler.call(event, 'zarmeza')

      expect(HTTParty).to have_received(:get).with('https://exercism.org/profiles/zarmeza')
    end

    it 'replies with the profile URL when it exists' do
      stub_response(200)

      described_class.handler.call(event, 'zarmeza')

      expect(event.responses).to contain_exactly(profile_uri)
    end

    it 'replies that the profile is unknown on a 4xx' do
      stub_response(404)

      described_class.handler.call(event, 'ghost')

      expect(event.responses).to contain_exactly('*ghost* does not appear to be a valid exercism public profile')
    end

    it 'reports the status code on a 5xx' do
      stub_response(503)

      described_class.handler.call(event, 'zarmeza')

      expect(event.responses).to contain_exactly('Unexpected error: (HTTP 503)')
    end
  end
end
