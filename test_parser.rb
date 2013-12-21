#!/usr/bin/env ruby

require_relative 'lib/parse_config'
require 'awesome_print'

parser = SwitchConfigParser.new(IO.readlines("data/switch.config"))

parser.parse_config

ap parser.get_interfaces

