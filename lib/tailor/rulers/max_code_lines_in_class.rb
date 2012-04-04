require_relative '../ruler'
require_relative '../lexer_constants'

class Tailor
  module Rulers
    class MaxCodeLinesInClassRuler < Tailor::Ruler
      include LexerConstants

      def initialize(config)
        super(config)
        @class_start_lines = []
        @kw_start_lines = []
        @end_last_class = false
      end

      def ignored_nl_update(lexed_line, lineno, column)
        return if @class_start_lines.empty?
        return if lexed_line.only_spaces?
        return if lexed_line.comment_line?

        @class_start_lines.each do |line|
          line[:count] += 1
          log "Class from line #{line[:lineno]} now at #{line[:count]} lines."
        end

        if @end_last_class
          measure(@class_start_lines.last[:count],
            @class_start_lines.last[:lineno],
            @class_start_lines.last[:column])
          @class_start_lines.pop
          @end_last_class = false
        end
      end

      def kw_update(token, modifier, loop_with_do, lineno, column)
        if token == "class" || token == "module"
          @class_start_lines << { lineno: lineno, column: column, count: 0 }
          log "Class start lines: #{@class_start_lines}"
        end

        unless modifier ||
          !KEYWORDS_TO_INDENT.include?(token) ||
          (token == "do" && loop_with_do) ||
          CONTINUATION_KEYWORDS.include?(token)
          @kw_start_lines << lineno
          log "Keyword start lines: #{@kw_start_lines}"
        end

        if token == "end"
          log "Got 'end' of class/module."

          unless @class_start_lines.empty?
            if @class_start_lines.last[:lineno] == @kw_start_lines.last
              msg = "Class/module from line #{@class_start_lines.last[:lineno]}"
              msg << " was #{@class_start_lines.last[:count]} lines long."
              log msg
              @end_last_class = true
            end
          end

          @kw_start_lines.pop
          log "End of keyword statement.  Keywords: #{@kw_start_lines}"
        end
      end

      def nl_update(lexed_line, lineno, column)
        ignored_nl_update(lexed_line, lineno, column)
      end

      # Checks to see if the actual count of code lines in the class is greater
      # than the value in +@config+.
      #
      # @param [Fixnum] actual_count The number of code lines found.
      # @param [Fixnum] lineno The line the potential problem is on.
      # @param [Fixnum] column The column the potential problem is on.
      def measure(actual_count, lineno, column)
        if actual_count > @config
          @problems << Problem.new(:code_lines_in_class, lineno, column,
            { actual_count: actual_count, should_be_at: @config })
        end
      end
    end
  end
end
