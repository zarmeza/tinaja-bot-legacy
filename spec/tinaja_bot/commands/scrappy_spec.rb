# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'tinaja-bot/commands/scrappy'

RSpec.describe TinajaBot::Commands::Scrappy do
  let(:event) { FakeEvent.new(user_id: 3) }
  let(:browser) { instance_double(Watir::Browser) }
  let(:screenshot) { instance_double(Watir::Screenshot) }

  # scrappy writes screenshot.png / backtrace.txt relative to the working
  # directory, so run each example in a throwaway one.
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  before do
    # Most examples are about what happens once Chrome is up; the race is
    # covered by overriding this in the contexts below.
    allow(described_class).to receive(:browser_ready?).and_return(true)
    allow(Watir::Browser).to receive(:new).and_return(browser)
    allow(browser).to receive(:goto)
    allow(browser).to receive(:screenshot).and_return(screenshot)
    allow(screenshot).to receive(:save) { |path| FileUtils.touch(path) }
  end

  context 'without a url' do
    it 'asks the user for one' do
      described_class.handler.call(event)

      expect(event.responses).to contain_exactly('<@3> gib url plz')
    end

    it 'does not open a browser' do
      described_class.handler.call(event)

      expect(Watir::Browser).not_to have_received(:new)
    end
  end

  context 'with a url' do
    it 'visits the url and attaches the screenshot' do
      described_class.handler.call(event, 'https://example.com')

      aggregate_failures do
        expect(browser).to have_received(:goto).with('https://example.com')
        expect(screenshot).to have_received(:save).with('screenshot.png')
        expect(event.files.map { |file| File.basename(file.path) }).to eq(['screenshot.png'])
      end
    end

    # discordrb hands the message body over as a single string, so this join is
    # a safety net rather than the normal path.
    it 'space-joins if it is given more than one argument' do
      described_class.handler.call(event, 'https://example.com', 'a', 'b')

      expect(browser).to have_received(:goto).with('https://example.com a b')
    end
  end

  context 'when the WebDriver is not accepting connections yet' do
    before do
      allow(described_class).to receive(:browser_ready?).and_return(false)
      stub_const('TinajaBot::Commands::Scrappy::BROWSER_READY_TIMEOUT', 0)
      stub_const('TinajaBot::Commands::Scrappy::BROWSER_POLL_INTERVAL', 0)
    end

    it 'says the browser is booting instead of raising' do
      described_class.handler.call(event, 'https://example.com')

      aggregate_failures do
        expect(event.responses.first).to eq('<@3> chrome is still booting, give it a sec and try again')
        expect(Watir::Browser).not_to have_received(:new)
        expect(event.files).to be_empty
      end
    end
  end

  context 'when the browser only becomes reachable after waiting' do
    before do
      allow(described_class).to receive(:browser_ready?).and_return(false, true)
      stub_const('TinajaBot::Commands::Scrappy::BROWSER_READY_TIMEOUT', 30)
      stub_const('TinajaBot::Commands::Scrappy::BROWSER_POLL_INTERVAL', 0)
    end

    it 'captures the screenshot once the port opens' do
      described_class.handler.call(event, 'https://example.com')

      expect(browser).to have_received(:goto).with('https://example.com')
    end
  end

  context 'when the browser driver raises UnknownError' do
    let(:driver_error) do
      raise Selenium::WebDriver::Error::UnknownError, 'session went away'
    rescue Selenium::WebDriver::Error::UnknownError => e
      e
    end

    before { allow(browser).to receive(:goto).and_raise(driver_error) }

    it 'reports the error and attaches the backtrace' do
      described_class.handler.call(event, 'https://example.com')

      aggregate_failures do
        expect(event.responses.first).to include('session went away')
        expect(event.files.map { |file| File.basename(file.path) }).to eq(['backtrace.txt'])
      end
    end
  end
end
