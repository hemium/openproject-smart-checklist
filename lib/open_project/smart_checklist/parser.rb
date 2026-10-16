# frozen_string_literal: true

module OpenProject
  module SmartChecklist
    # Parses the Jira-style smart checklist markdown format.
    #
    # Canonical forms:
    #   # text    (also ##, ###) header
    #   - [ ] text   todo
    #   - [x] text / - [X] text   done
    #   - [~] text   in progress
    #   - [-] text   skipped
    #   > text    note attached to the previous item
    #
    # Jira Smart Checklist shorthand (input only):
    #   - text   todo
    #   + text   done
    #   ~ text   in progress
    #   x text   skipped
    #
    # Any other non-blank line is a todo item with that text.
    module Parser
      STATUSES = %i[todo done in_progress skipped].freeze

      HEADER = /\A\s*\#{1,3}\s+(?<text>.+)\z/
      CHECKBOX = /\A\s*-\s*\[(?<mark> |x|X|~|-)\]\s*(?<text>.*)\z/
      NOTE = /\A\s*>\s*(?<text>.*)\z/
      SHORTHAND = /\A\s*(?<mark>[-+~x])\s+(?<text>.+)\z/

      SHORTHAND_STATUSES = {
        "-" => :todo,
        "+" => :done,
        "~" => :in_progress,
        "x" => :skipped
      }.freeze

      CHECKBOX_STATUSES = {
        " " => :todo,
        "x" => :done,
        "X" => :done,
        "~" => :in_progress,
        "-" => :skipped
      }.freeze

      module_function

      # Returns an array of entries:
      #   { type: :header, text: String }
      #   { type: :item, text: String, status: Symbol, notes: [String] }
      def parse(text)
        items = []
        last_item = nil

        text.to_s.each_line do |line|
          line = line.strip
          next if line.empty?

          last_item = parse_line(line, items, last_item)
        end

        items
      end

      def parse_line(line, items, last_item)
        case line
        when HEADER
          items << { type: :header, text: Regexp.last_match(:text).strip }
          nil
        when CHECKBOX
          append_item(items, Regexp.last_match(:text), CHECKBOX_STATUSES.fetch(Regexp.last_match(:mark)))
        when NOTE
          last_item&.dig(:notes)&.push(Regexp.last_match(:text))
          last_item
        when SHORTHAND
          append_item(items, Regexp.last_match(:text), SHORTHAND_STATUSES.fetch(Regexp.last_match(:mark)))
        else
          append_item(items, line, :todo)
        end
      end

      # Serializes parsed entries back to the canonical bracket form.
      def serialize(entries)
        entries.filter_map do |entry|
          case entry[:type]
          when :header
            "# #{entry[:text]}"
          when :item
            lines = ["- [#{status_mark(entry[:status])}] #{entry[:text]}"]
            lines.concat(Array(entry[:notes]).map { |note| "> #{note}" })
            lines.join("\n")
          end
        end.join("\n")
      end

      def status_mark(status)
        { todo: " ", done: "x", in_progress: "~", skipped: "-" }.fetch(status)
      end

      # Returns progress counts for the given text:
      #   { total:, done:, inProgress:, skipped:, todo:, percent: }
      # percent = round(100 * done / (total - skipped)), 0 when the denominator is 0.
      def progress(text)
        result = { total: 0, done: 0, inProgress: 0, skipped: 0, todo: 0 }

        parse(text).each do |entry|
          next unless entry[:type] == :item

          result[:total] += 1
          result[progress_key(entry[:status])] += 1
        end

        result[:percent] = percent_for(result)
        result
      end

      def percent_for(result)
        countable = result[:total] - result[:skipped]
        countable.zero? ? 0 : (100.0 * result[:done] / countable).round
      end

      def progress_key(status)
        status == :in_progress ? :inProgress : status
      end

      def append_item(items, text, status)
        item = { type: :item, text: text.to_s.strip, status:, notes: [] }
        items << item
        item
      end
    end
  end
end
