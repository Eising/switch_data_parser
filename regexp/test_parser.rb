#!/usr/bin/env ruby

require_relative 'parse_config'
require_relative 'parse_bridge_table'
require_relative 'switch'
require_relative 'machine'

require 'awesome_print'
require 'hash_deep_merge'
require 'pp'
require 'yaml'

# network consists of machines and switches
# network = Network.new
# view of switches:
# * see which machine interfaces are visible on which ports
# machines view:
# * see which switches each interface is plugged into

switch_config = SwitchConfigParser.new(IO.readlines("../data/switch.config"))
bridge_table  = SwitchBridgeTableParser.new(IO.readlines("../data/bridge_table.config"))

# machine config is already a hash so need to run through a parser first, although we could do with improving mcollective plugin to output proper json / yaml..
#machines = Machines.new(YAML.load_file('../data/mcollective.config'))

#machines.find_machine('d4bed9fbbb65')

switch = Switch.new
switch.load_switch_config(switch_config.config)
switch.load_bridge_table(bridge_table.config)
#switch.load_machines(machines)
switch.combine_data
ap switch.config.to_hash

#machines.combine_data(switch)

