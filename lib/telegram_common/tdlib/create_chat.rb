module TelegramCommon::Tdlib
  class CreateChat < Command
    def call(title, user_ids)
      @client.on_ready(limit: 5) do |client|
        user_ids.each do |id|
          client.broadcast_and_receive('@type' => 'getUser', 'user_id' => id)
        end

        sleep 1

        chat = client.broadcast_and_receive('@type' => 'createNewBasicGroupChat',
                                            'title' => title,
                                            'user_ids' => user_ids)

        sleep 1

        client.broadcast_and_receive('@type' => 'toggleBasicGroupAdministrators',
                                     'basic_group_id' => chat.dig('type', 'basic_group_id'),
                                     'everyone_is_administrator' => false)
        chat
      end
    end
  end
end
