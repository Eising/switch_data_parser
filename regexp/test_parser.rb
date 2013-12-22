#!/usr/bin/env ruby

require_relative 'parse_config'
require_relative 'parse_bridge_table'

require 'awesome_print'
require 'hash_deep_merge'

#config_parser = SwitchConfigParser.new(IO.readlines("../data/switch.config"))
#config_parser.parse_config
#ap config_parser.get_config

bridge_table_parser = SwitchBridgeTableParser.new(IO.readlines("../data/bridge_table.config"))
bridge_table_parser.parse_config
ap bridge_table_parser.get_config

#ap config_parser.get_config.deep_merge(bridge_table_parser.get_config)
