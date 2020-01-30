#!/usr/bin/env ruby

require "listen"
require "optparse"
require "fileutils"
require "open3"

class Saturn
  def self.render(input) # string -> string
    text_lines = []
    code_lines = []
    blocks = []
    state = :text # text | code | hiddencode
    pipes = []
    original_stdout = $stdout

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

    $stdout = original_stdout

    blocks
      .filter { |x| x[:type] == :text }
      .map { |x| x[:body] }
      .zip(
        blocks
          .filter { |x| x[:type] == :code }
          .map { |x| x[:hidden] ? "" : "```\n#{x[:body]}```" }
          .zip(renderings)
      )
      .join("\n")
  end
end

if __FILE__ == $0
  options = {}
  op = OptionParser.new do |opts|
    opts.banner = "Usage: saturn.rb [options]"

    opts.on("-v", "--version", "Run verbosely") do
      puts("saturn.rb v0")
      exit(0)
    end

    opts.on("-l", "--listen", "Listen for changes") do
      puts("listening for changes in directory ./")
      FileUtils.mkdir_p("./build")

      watcher = Listen.to('.') do |modified, added, removed|
        filename = (modified || added).first
        if filename
          if File.extname(filename) == ".saturn"
            output_filename = "./build/#{File.basename(filename)}.html"
            File.open(output_filename, "w") do |f|
              input = File.read(filename)
              markdown = Saturn.render(input)
              input_buffer, out_buffer = IO.pipe
              command = "pandoc -f gfm -t html --metadata title=titleName --template=#{__dir__}/saturn"
              stdout, stderr, status = Open3.capture3(command, :stdin_data => markdown)

              if status != 0
                $stderr.puts("'#{filename}' -> '#{output_filename}' failed")
                $stderr.puts(stderr)
              else
                f.write(stdout)
                $stderr.puts("'#{filename}' -> '#{output_filename}' successful")
              end
            end
          end
        end
      end

      watcher.start

      sleep
    end
  end
  op.parse!

  STDOUT.puts(Saturn.render(STDIN.read))
end
