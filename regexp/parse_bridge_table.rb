#!/usr/bin/env ruby

class SwitchBridgeTableParser
  def initialize(io, debug = false)
    @io         = io
    @debug      = debug
    @config = {}
  end

  def parse_config
    @io.each do |line|

      # FIXME:
      # * would adding the management interfaces be usedful?
      # * management interfaces have no interface entry in the bridge table so
      #   skip them for now...
      next if line.split.length != 4

      vlan, mac, interface, mode  = *line.split

      # FIXME:
      # * ignore channel interfaces for now..
      next if interface == "ch2"

      identifier = "interface_ethernet_#{interface}".gsub!('/', '_')

      @config[:interface] ||= {}
      @config[:interface][:ethernet] ||= {}
      @config[:interface][:ethernet][identifier] ||= {}
      @config[:interface][:ethernet][identifier][:switchport] ||= {}
      @config[:interface][:ethernet][identifier][:switchport][:vlans] ||= {}
      @config[:interface][:ethernet][identifier][:switchport][:vlans][:add] ||= {}
      @config[:interface][:ethernet][identifier][:switchport][:vlans][:add][vlan] ||= {}
      @config[:interface][:ethernet][identifier][:switchport][:vlans][:add][vlan].merge!({ mac => mode })
    end
  end

  def get_config
    @config
  end
end
