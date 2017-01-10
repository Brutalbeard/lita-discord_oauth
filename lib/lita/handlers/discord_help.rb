require 'lita/handler/chat_router'

module Lita
  # A namespace to hold all subclasses of {Handler}.
  module Handlers
    # Provides online help about Lita commands for users.
    class DiscordHelp
      extend Lita::Handler::ChatRouter

      route(/^help\s*(.+)?/, :help, command: true, help: {
          "help" => t("help.help_value"),
          t("help.help_command_key") => t("help.help_command_value")
      })

      # Outputs help information about Lita commands.
      # @param response [Lita::Response] The response object.
      # @return [void]
      def help(response)
        output = build_help(response)
        output = filter_help(output, response)

        output = "```\n" + output.join("\n") + "\n```"

        split_message(output)

        response.reply_privately(output)
      end

      private

      def split_message(message)
        max_length = 2000 - 25 # Substract 25 for mention safety
        messages = Array.new

        if message.length < max_length
          messages.push(message)
        else
          parsed = ''
          message_copy = message

          while parsed != message do
            part = get_message_part(message_copy, max_length)

            Lita.logger.debug("Part: #{part}")

            messages.push(part)
            parsed += part
            message_copy = message_copy[part.length - 1, -1]
          end
        end

        messages
      end

      def get_message_part(message, limit)
        part = message[0, limit - 1]
        break_index = part.rindex("\n")

        message[0, break_index]
      end

      def table_row(key, value)
        key_width = 30
        value_width = 107

        key_text = key.ljust(key_width, ' ')

        value_words = value.split(' ')

        value_text = ''
        value_line = ''

        value_words.each do |word|
          new_value_line = "#{value_line} #{word}"

          if new_value_line.length > value_width
            value_text += "#{value_line}\n" + ''.ljust(key_width + 1, ' ')
            value_line = word
          else
            value_line = "#{value_line} #{word}"
          end

        end

        if value_line.length > 0
          value_text = "#{value_text}\n" + ''.ljust(key_width + 1, ' ') + "#{value_line}"
        end

        key_text + value_text
      end

      # Checks if the user is authorized to at least one of the given groups.
      def authorized?(user, required_groups)
        required_groups.nil? || required_groups.any? do |group|
          robot.auth.user_in_group?(user, group)
        end
      end

      # Creates an array of help info for all registered routes.
      def build_help(response)
        robot.handlers.map do |handler|
          next unless handler.respond_to?(:routes)

          handler.routes.map do |route|
            route.help.map do |command, description|
              if authorized?(response.user, route.required_groups)
                help_command(route, command, description)
              end
            end
          end
        end.flatten.compact
      end

      # Filters the help output by an optional command.
      def filter_help(output, response)
        filter = response.matches[0][0]

        if filter
          output.select { |line| /(?:@?#{name}[:,]?)?#{filter}/i === line }
        else
          output
        end
      end

      # Formats an individual command's help message.
      def help_command(route, command, description)
        command = "#{name}: #{command}" if route.command?

        table_row(command, description)
      end

      # The way the bot should be addressed in order to trigger a command.
      def name
        robot.config.robot.mention_name || robot.config.robot.name
      end
    end

    Lita.register_handler(DiscordHelp)
  end
end
