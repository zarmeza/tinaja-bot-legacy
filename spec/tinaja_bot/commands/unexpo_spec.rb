# frozen_string_literal: true

require 'tinaja-bot/commands/unexpo'

RSpec.describe TinajaBot::Commands::Unexpo do
  it 'greets the invoking user' do
    event = FakeEvent.new(user_id: 99)

    described_class.handler.call(event)

    expect(event.responses).to contain_exactly('Hola <@99>! *Tuetudiate en el poli?*')
  end

  it 'interpolates whichever user invoked it' do
    event = FakeEvent.new(user_id: 1234)

    described_class.handler.call(event)

    expect(event.responses.first).to include('<@1234>')
  end
end
