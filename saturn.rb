#!/usr/bin/env ruby
require 'json'

def mattr_reader(*syms, instance_reader: true, instance_accessor: true, default: nil, location: nil)
  raise TypeError, "module attributes should be defined directly on class, not singleton" if singleton_class?
  location ||= caller_locations(1, 1).first

  definition = []
  syms.each do |sym|
    raise NameError.new("invalid attribute name: #{sym}") unless /\A[_A-Za-z]\w*\z/.match?(sym)

    definition << "def self.#{sym}; @@#{sym}; end"

    if instance_reader && instance_accessor
      definition << "def #{sym}; @@#{sym}; end"
    end

    sym_default_value = (block_given? && default.nil?) ? yield : default
    class_variable_set("@@#{sym}", sym_default_value) unless sym_default_value.nil? && class_variable_defined?("@@#{sym}")
  end

  module_eval(definition.join(";"), location.path, location.lineno)
end
alias :cattr_reader :mattr_reader
def mattr_writer(*syms, instance_writer: true, instance_accessor: true, default: nil, location: nil)
  raise TypeError, "module attributes should be defined directly on class, not singleton" if singleton_class?
  location ||= caller_locations(1, 1).first

  definition = []
  syms.each do |sym|
    raise NameError.new("invalid attribute name: #{sym}") unless /\A[_A-Za-z]\w*\z/.match?(sym)
    definition << "def self.#{sym}=(val); @@#{sym} = val; end"

    if instance_writer && instance_accessor
      definition << "def #{sym}=(val); @@#{sym} = val; end"
    end

    sym_default_value = (block_given? && default.nil?) ? yield : default
    class_variable_set("@@#{sym}", sym_default_value) unless sym_default_value.nil? && class_variable_defined?("@@#{sym}")
  end

  module_eval(definition.join(";"), location.path, location.lineno)
end
alias :cattr_writer :mattr_writer
def mattr_accessor(*syms, instance_reader: true, instance_writer: true, instance_accessor: true, default: nil, &blk)
  location = caller_locations(1, 1).first
  mattr_reader(*syms, instance_reader: instance_reader, instance_accessor: instance_accessor, default: default, location: location, &blk)
  mattr_writer(*syms, instance_writer: instance_writer, instance_accessor: instance_accessor, default: default, location: location)
end
alias :cattr_accessor :mattr_accessor

PREAMBLE = <<-CODE
class Saturn
  cattr_accessor :pipes, :renderings
end
Saturn.pipes = []
Saturn.pipes << IO.pipe
$stdout = Saturn.pipes.last.last
CODE

GLUE = <<-CODE
Saturn.pipes << IO.pipe
$stdout = Saturn.pipes.last.last
CODE

FINALE = <<-CODE
Saturn.renderings = 
  Saturn.pipes
  .each { |pair| pair.last.close }
  .map(&:first)
  .map(&:read)
CODE

text_lines = []
code_lines = []

blocks = []

state = :text # text | code | hiddencode

(ARGF.read + "% hidden ruby\n% end\n").lines.each do |line|
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
  PREAMBLE +
  blocks
  .filter { |x| x[:type] == :code }
  .map { |x| x[:body] }
  .join(GLUE) +
  FINALE

eval(script)

STDOUT.puts(
  blocks
  .filter { |x| x[:type] == :text }
  .map { |x| x[:body] }
  .zip(
    blocks
      .filter { |x| x[:type] == :code }
      .map { |x| x[:hidden] ? "" : "```\n#{x[:body]}```" }
      .zip(Saturn.renderings)
  )
)