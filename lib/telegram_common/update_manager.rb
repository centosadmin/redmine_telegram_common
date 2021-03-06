class TelegramCommon::UpdateManager
  COMMON_COMMANDS = %w[help start connect]

  def initialize
    @handlers = []
  end

  def add_handler(handler)
    @handlers << handler
  end

  def handle_message(message)
    command_name = message.text.to_s.scan(%r{^/(\w+)}).flatten.first
    handle_common_command(message) if COMMON_COMMANDS.include?(command_name)
    @handlers.each { |handler| handler.call(message) }
  end

  private

  def handle_common_command(message)
    TelegramCommon::Bot.new(TelegramCommon.bot_token, message).call
  end
end
