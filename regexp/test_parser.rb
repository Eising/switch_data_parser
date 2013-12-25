#!/usr/bin/env ruby

require_relative 'parse_config'
require_relative 'parse_bridge_table'
require_relative 'switch'

require 'awesome_print'
require 'hash_deep_merge'
require 'pp'

config_parser = SwitchConfigParser.new(IO.readlines("../data/switch.config"))
config_parser.parse_config
switch_config = config_parser.get_config

bridge_table_parser = SwitchBridgeTableParser.new(IO.readlines("../data/bridge_table.config"))
bridge_table_parser.parse_config
bridge_table = bridge_table_parser.get_config

switch = Switch.new
switch.load_switch_config(switch_config)
switch.load_bridge_table(bridge_table)

switch.merge_bridge_table_entries_with_switch_config

ap switch.config.ethernet_interfaces
ap switch.to_hash

#ap switch_config
