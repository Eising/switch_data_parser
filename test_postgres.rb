#!/usr/bin/env ruby

require 'pg'
require 'awesome_print'

## add a switch

# $1 = switch
# $2 = switch stack
# $3 = network
query.prepare("add_network", "INSERT INTO host (name, stack_position, network_id) SELECT $1,  $2, id FROM network WHERE location = $3")

## add a switch interface
# $1 = switch interface description
# $2 = switch
# $3 = switch stack
query.prepare("add_switch_interface", "INSERT INTO switch_interface (description, host_id) SELECT $1, id FROM host WHERE name = $2 AND stack_position = $3")

# if we dont enforce 'unique' descriptions, there could be a problem..

# add an ethernet interface to the switch
# $1 = port
# $2 = description

# see if ethernet port exists on switch / switch stack, if it does then fail!
# otherwise, insert a row into switch interface and then connect ethernet to its id

# this has to be a select with a join to find the correct switch interface + switch host
query.prepare("add_ethernet", "INSERT INTO ethernet (port, switch_interface_id) SELECT $1, id FROM switch_interface WHERE identity = $2")
