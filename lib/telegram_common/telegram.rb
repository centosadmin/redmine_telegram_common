module TelegramCommon
  class Telegram
    def execute(command, config_path: nil, logger: nil, args: {})
      @command     = command
      @args        = args
      @logger      = logger || TELEGRAM_CLI_LOG
      @config_path = config_path || PHANTOMJS_CONFIG

      debug(command)
      debug(args)

      make_request
      fail response[1] if response[0] == 'failed'

      response[1]
    end

    private

    attr_reader :command, :args, :config_path, :logger, :api_result

    def make_request
      @api_result = `#{cli_command}`
      debug(api_result)
      api_result
    end

    def cli_command
      cmd = "#{phantomjs} #{config_path} \"#{api_url}\""
      debug(cmd)
      cmd
    end

    def phantomjs
      `which phantomjs`.strip
    end

    def api_url
      params = {
        command: command,
        args: args.to_json
      }
      base_api = if Rails.env.development?
                   # gulp watch on app/webogram
                   'http://localhost:8000/app/index.html'
                 else
                   "#{Setting.protocol}://#{Setting.host_name}/plugin_assets/redmine_telegram_common/webogram/index.html"
                 end
      "#{base_api}#/api?#{params.to_query}"
    end

    def debug(message)
      log(message)
    end

    def log(message, operation: 'debug')
      if logger && message
        logger.public_send(operation, message)
      end
    end

    def response
      api_result.scan(/(success|failed): (.*)/).flatten
    end
  end
end
