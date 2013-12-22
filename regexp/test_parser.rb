#!/usr/bin/env ruby

require_relative 'parse_config'
require_relative 'parse_bridge_table'
require_relative 'switch'

require 'awesome_print'
require 'hash_deep_merge'

config_parser = SwitchConfigParser.new(IO.readlines("../data/switch.config"))
config_parser.parse_config
switch_config = config_parser.get_config

bridge_table_parser = SwitchBridgeTableParser.new(IO.readlines("../data/bridge_table.config"))
bridge_table_parser.parse_config
bridge_table = bridge_table_parser.get_config

#ap config_parser.get_config[:interface][:ethernet].find_all { |name, interface|
#  interface[:port] == "5" and interface[:unit] == 'g' and interface[:stack_member] == "1"
#}

#ap switch_config
#ap bridge_table

#ap config_parser.get_config.deep_merge(bridge_table_parser.get_config)

switch = Switch.new
switch.load_bridge_table(bridge_table)
switch.load_switch_config(switch_config)

ap switch.config #.vlan_interfaces
#ap switch.config #.port_channel_interfaces

#switch.config.ethernet_interfaces.each do |identifier, interface|
#  ap identifier
#  ap interface
#end

#switch.bridge_table.interfaces.each do |identifier, line|
#  p line
#end

#puts '-----------------------'
#ap switch.bridge_table
