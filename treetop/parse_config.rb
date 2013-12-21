#!/usr/bin/env ruby

require 'treetop'
require 'awesome_print'

module SwitchPort
  class InterfaceType < Treetop::Runtime::SyntaxNode
    def to_s
      return self.text_value
    end
  end

  class SwitchStack < Treetop::Runtime::SyntaxNode
    def to_s
      return self.text_value
    end
  end

  class Speed < Treetop::Runtime::SyntaxNode
    def to_s
      return self.text_value
    end
  end

  class EthernetPort < Treetop::Runtime::SyntaxNode
    def to_s
      return self.text_value
    end
  end
end

class Parser
  attr_reader :parser

  def initialize(string)
    Treetop.load('switch.treetop')

    @parser = SwitchPortParser.new
    tree = @parser.parse(string)

    raise Exception, "Parse error at offset: #{@parser.index}" if tree.nil?

    @tree = clean_tree(tree)
  end

  def get_tree
    @tree
  end

  def clean_tree(root_node)
    return if root_node.elements.nil?

    root_node.elements.delete_if { |node| node.class.name == "Treetop::Runtime::SyntaxNode" }
    root_node.elements.each { |node| clean_tree(node) }
  end
end

config = File.read('../data/switch.config').chomp
parser = Parser.new(config)

ap parser.get_tree
