module TelegramCommon::Tdlib
  class GetUser < Command
    def call(user_id)
      @client.on_ready do |client|
        client.broadcast_and_receive('@type' => 'getUser', 'user_id' => user_id)
      end
    end
  end
end
