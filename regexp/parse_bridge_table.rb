#!/usr/bin/env ruby

class SwitchBridgeTableParser
  def initialize(io, debug = false)
    @io         = io
    @debug      = debug
    @config = {}
  end

  def parse_config
    @io.each do |line|

      case line.split.length
      when 4
        vlan, mac, interface, mode  = *line.split
      when 3
        vlan, mac, mode, interface  = *line.split, "none"
      else
        raise ArgumentError, "could not parse line: #{line}"
      end

      interface.gsub!('/', '_')

      @config ||= {}
      @config[interface] ||= {}

      case interface
      when /none/
      when /ch2/
      when /[0-9]_[a-z]{0,2}[0-9]{0,2}/
        @config[interface][:stack_member] = interface.split('_')[0]
        @config[interface][:unit] = interface.split('_')[1].match(/[0-9]/)[0]
        @config[interface][:port] = interface.split('_')[1].match(/[a-z]+/)[0]
      else
        raise ArgumentError, "unknown interface type: #{interface}"
      end

      #@config[interface][:interface] ||= {}
      #@config[interface][:interface].merge!()

      @config[interface][:vlan] ||= {}
      @config[interface][:vlan][vlan] ||= {}
      @config[interface][:vlan][vlan].merge!({ mac => mode })
    end
  end

  def get_config
    @config
  end
end
