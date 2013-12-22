#!/usr/bin/env ruby

class SwitchBridgeTableParser
  def initialize(io, debug = false)
    @io         = io
    @debug      = debug
    @interfaces = {}
  end

  def parse_config
    @io.each do |line|

      # FIXME:
      # * would adding the management interfaces be usedful?
      # * management interfaces have no interface entry in the bridge table so
      #   skip them for now...
      next if line.split.length != 4

      vlan, mac, interface, mode  = *line.split

      identifier = "interface_ethernet_#{interface}".gsub!('/', '_')

      @interfaces[identifier] ||= {}
      @interfaces[identifier][:switchport] ||= {}
      @interfaces[identifier][:switchport][:vlans] ||= {}
      @interfaces[identifier][:switchport][:vlans][:add] ||= {}
      @interfaces[identifier][:switchport][:vlans][:add][vlan] ||= {}
      @interfaces[identifier][:switchport][:vlans][:add][vlan].merge!({ mac => mode })
    end
  end

  def get_interfaces
    @interfaces
  end
end
