# frozen_string_literal: true

require 'stringio'

require_relative '../script/discord_reply'

RSpec.describe DiscordReply do
  let(:http) { instance_double(Net::HTTP) }
  let(:requests) { [] }
  let(:replies) { [] }
  let(:screen) { StringIO.new }
  let(:session) { "\nhola\nq\n" }

  before do
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request) do |request|
      requests << request
      replies.shift
    end
    described_class.input = StringIO.new(session)
    described_class.output = screen
  end

  after do
    described_class.input = nil
    described_class.output = nil
  end

  def channel
    { 'id' => '1045', 'name' => 'general', 'guild_id' => '90' }
  end

  def created
    { 'id' => '999', 'channel_id' => '1045', 'guild_id' => '90' }
  end

  def ok(payload)
    response(Net::HTTPOK, '200', payload)
  end

  def error(payload)
    response(Net::HTTPBadRequest, '400', payload)
  end

  # Net::HTTPResponse#body calls read_body, which refuses to run without a
  # socket unless @read is set — the flag a real response gets after streaming.
  def response(klass, code, payload)
    klass.new('1.1', code, 'Stub').tap do |res|
      res.body = JSON.generate(payload)
      res.instance_variable_set(:@read, true)
    end
  end

  def posted
    requests.find { |request| request.is_a?(Net::HTTP::Post) }
  end

  def body_of_post
    JSON.parse(posted.body)
  end

  context 'when the message id is left blank' do
    before { replies.push(ok(channel), ok(created)) }

    it 'posts a plain message with no reply reference' do
      described_class.call('tok', '1045')

      aggregate_failures do
        expect(body_of_post).to eq('content' => 'hola', 'allowed_mentions' => { 'replied_user' => false })
        expect(screen.string).to include('discord.com/channels/90/1045/999')
      end
    end
  end

  context 'when a message id is given' do
    let(:session) { "999\njalabola\nq\n" }

    before { replies.push(ok(channel), ok(created)) }

    it 'references the message it replies to' do
      described_class.call('tok', '1045')

      expect(body_of_post['message_reference']).to eq('message_id' => '999')
    end
  end

  context 'when the message id is not a snowflake' do
    let(:session) { "abc\nq\n" }

    before { replies.push(ok(channel)) }

    it 'says so and keeps prompting instead of sending' do
      described_class.call('tok', '1045')

      aggregate_failures do
        expect(screen.string).to include('abc is not a message id')
        expect(posted).to be_nil
      end
    end
  end

  context 'when the channel does not exist' do
    let(:session) { "1045\nq\n" }

    before { replies.push(error({ 'message' => 'Unknown Channel' }), ok(channel)) }

    it 'reports why and asks again' do
      described_class.call('tok', '123')

      expect(screen.string).to match(/Unknown Channel.*#general/m)
    end
  end

  context 'when Discord rejects the message' do
    before { replies.push(ok(channel), error({ 'message' => 'Unknown Message' })) }

    it 'prints the reason and returns to the prompt' do
      described_class.call('tok', '1045')

      expect(screen.string).to include('Unknown Message')
    end
  end

  context 'when the user quits' do
    let(:session) { "q\n" }

    before { replies.push(ok(channel)) }

    it 'stops without posting' do
      described_class.call('tok', '1045')

      expect(posted).to be_nil
    end
  end
end
