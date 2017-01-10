require 'discordrb'

module Lita
  module Adapters
    class Discord_oauth < Adapter
      config :token, type: String, required: true
      config :client, type: String, required: true

      def initialize(robot)
        super
        @client = ::Discordrb::Bot.new token: config.token, client_id: config.client
      end

      def run
        STDOUT.write('Starting')
        @client.ready do |e|
          robot.trigger(:connected)

          @client.message do |event|
            message = event.message
            message_text = message.content

            puts message_text
            puts message
            puts message.author.id

            user = Lita::User.find_by_id(message.author.id)
            user = Lita::User.create(user) unless user

            channel = event.channel.id

            source = Lita::Source.new(user: user, room: channel)
            msg = Lita::Message.new(robot, message_text, source)

            robot.receive(msg) #unless message.from_bot?

          end
        end


        @client.run
      end

      def shut_down
        @client.stop
      end

      def send_messages(target, messages)
        puts target
        puts target.user

        mention = @client.user(target.user).mention

        puts mention

        messages.each do |message|
          if mention
            message = mention + ',\n' + message

            puts message

            @client.send_message(target.channel, message)
          end
        end
      end

    end

    Lita.register_adapter(:discord_oauth, Discord_oauth)
  end
end
