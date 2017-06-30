require 'telegram/bot'

module TelegramCommon
  class Bot
    include BotCommand::Start
    include BotCommand::Connect
    include BotCommand::Help

    attr_reader :bot_token, :logger, :command

    def initialize(bot_token, command, logger = default_logger)
      @bot_token = bot_token
      @logger = logger
      @command = initialize_command(command)
    end

    def call
      TelegramCommon.set_locale

      return send_blocked_message if account.blocked?

      execute_command
    end

    def plugin_name
      bot_token_setting = Setting.where('value LIKE ?', "%#{bot_token}%").first
      bot_token_setting.name if bot_token_setting.present?
    end

    private

    def initialize_command(command)
      command.is_a?(Telegram::Bot::Types::Message) ? command : Telegram::Bot::Types::Message.new(command)
    end

    def execute_command
      return unless available_commands.include?(command_name)

      if private_command?
        execute_private_command
      else
        execute_group_command
      end
    end

    def private_command?
      command.chat.type == 'private'
    end

    def available_commands
      (private_commands + group_commands).uniq
    end

    def execute_private_command
      if private_commands.include?(command_name)
        send(command_name)
      else
        send_message(I18n.t('telegram_common.bot.private.group_command'))
      end
    end

    def execute_group_command
      if group_commands.include?(command_name)
        send(command_name)
      else
        send_message(I18n.t('telegram_common.bot.group.private_command'))
      end
    end

    def command_text
      @command_text ||= command.text.to_s
    end

    def command_name
      @command_name ||= command_text.scan(%r{^/(\w+)}).flatten.first
    end

    def send_message(message, params: {})
      message_params = {
        chat_id: chat_id,
        message: message,
        bot_token: bot_token,
      }.merge(params)

      logger.debug 'TelegramCommon::Bot#send_message'
      logger.debug "chat_id: #{chat_id}"
      logger.debug "message: #{message}"
      logger.debug "params: #{params}"

      MessageSender.call(message_params)
    end

    def send_blocked_message
      send_message(I18n.t('telegram_common.bot.connect.blocked', unblock: ((account.blocked_at+1.hour-Time.zone.now)/60).to_i))
    end

    def chat_id
      command.chat.id
    end

    def user
      @user ||= command.from
    end

    def account
      @account ||= fetch_account
    end

    def fetch_account
      Account.where(telegram_id: user.id).first_or_initialize
    end

    def default_logger
      @logger ||= Logger.new(Rails.root.join('log/telegram_common', 'bot.log'))
    end
  end
end
