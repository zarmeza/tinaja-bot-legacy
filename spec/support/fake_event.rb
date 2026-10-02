# frozen_string_literal: true

# Minimal stand-in for a discordrb message event. Records what a command did
# instead of opening a gateway connection, so command handlers can be exercised
# directly.
class FakeEvent
  User = Struct.new(:id)

  attr_reader :responses, :files, :user

  def initialize(user_id: 42)
    @user = User.new(user_id)
    @responses = []
    @files = []
  end

  def respond(message)
    @responses << message
    nil
  end

  def send_file(io)
    @files << io
    nil
  end
end
