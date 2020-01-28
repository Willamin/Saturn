#!/usr/bin/env ruby
class Saturn
  def self.render(input) # string -> string
    text_lines = []
    code_lines = []
    blocks = []
    state = :text # text | code | hiddencode
    pipes = []

    (input + "% hidden ruby\n% end\n").lines.each do |line|
      case state
      when :text
        if line.chomp == "% ruby"
          blocks << { type: :text, body: text_lines.join, hidden: false }
          text_lines = []
          state = :code
          next
        end
        if line.chomp == "% hidden ruby"
          blocks << { type: :text, body: text_lines.join, hidden: false }
          text_lines = []
          state = :hiddencode
          next
        end
        text_lines << line
      when :code, :hiddencode
        if line.chomp == "% end"
          blocks << { type: :code, body: code_lines.join, hidden: state == :hiddencode }
          code_lines = []
          state = :text
          next
        end
        code_lines << line
      end
    end

    script =
      blocks
        .filter { |x| x[:type] == :code }
        .map { |x| x[:body] }
        .join("pipes << IO.pipe\n$stdout = pipes.last.last\n")

    pipes = []
    pipes << IO.pipe
    $stdout = pipes.last.last
    eval(script)
    renderings = 
      pipes
        .each { |pair| pair.last.close }
        .map(&:first)
        .map(&:read)

    blocks
      .filter { |x| x[:type] == :text }
      .map { |x| x[:body] }
      .zip(
        blocks
          .filter { |x| x[:type] == :code }
          .map { |x| x[:hidden] ? "" : "```\n#{x[:body]}```" }
          .zip(renderings)
      )
  end
end

if __FILE__ == $0
  STDOUT.puts(Saturn.render(STDIN.read))
end
