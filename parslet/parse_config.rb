#!/usr/bin/env ruby

require 'awesome_print'
require 'parslet'

class SwitchConfigParslet < Parslet::Parser

  rule(:spaces) { match('\s').repeat(1) }
  rule(:spaces?) { spaces.maybe }

  rule(:interface_prefix)       { (spaces.absnt? >> any).repeat.as(:interface) >> spaces }
  rule(:interface_type)         { (spaces.absnt? >> any).repeat.as(:type) >> spaces }
  rule(:interface_stack_member) { (spaces.absnt? >> match('[0-9]')).as(:stack_member) >> str('/') }
  rule(:interface_port_type)    { (spaces.absnt? >> match('[a-z]').repeat(1)).as(:port_type) }
  rule(:interface_port)         { (spaces.absnt? >> match('[0-9]').repeat(1)).as(:port) }

  rule(:interface_config) {
    interface_prefix >>
    interface_type >>
    interface_stack_member >>
    interface_port_type >>
    interface_port
  }

  root(:interface_config)
end

config = File.read('../switch.config').chomp

ap SwitchConfigParslet.new.parse(config)
