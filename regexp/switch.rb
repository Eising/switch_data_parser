#!/usr/bin/env ruby

class Switch

  attr_accessor :config
  attr_accessor :bridge_table

  def load_switch_config(config)
    @config = Switch::Config.new(config)
  end

  def load_bridge_table(config)
    @bridge_table = Switch::Bridge::Table.new(config)
  end

#  def merge_bridge_table
#    @config.merge(@bridge_table)
#  end

  module Bridge
    class Table
      attr_reader :interfaces

      def initialize(table)
        @table      = table
        @interfaces = {}

        self.objectify
      end

      def objectify
        @table.each do |identifier, entry|
          @interfaces[identifier] = Switch::Bridge::Entry.new(identifier, entry)
        end
      end
    end

    class Entry
      attr_reader :name, :port, :unit, :switch_member, :vlans

      def initialize(identifier, entry)
        @identifier    = identifier
        @port          = entry[:port]
        @unit          = entry[:unit]
        @switch_member = entry[:stack_member]
        @vlans         = Switch::Interface::Attribute::Vlans.new(entry[:vlan]) unless entry[:vlan].nil?
      end
    end
  end

  class Config
    attr_accessor :ethernet_interfaces, :vlan_interfaces, :port_channel_interfaces

    def initialize(config)
      @config                  = config
      @ethernet_interfaces     = {}
      @vlan_interfaces         = {}
      @port_channel_interfaces = {}

      self.objectify
    end

    def objectify
      @config[:interface].each do |type, interfaces|

        case type

        when :ethernet
          interfaces.each do |identifier, interface|
            @ethernet_interfaces[identifier] = Switch::Interface::Ethernet.new(identifier, interface)
          end

        when :vlan
          interfaces.each do |identifier, interface|
            @vlan_interfaces[identifier] = Switch::Interface::Vlan.new(identifier, interface)
          end

        when :port_channel
          interfaces.each do |identifier, interface|
            @port_channel_interfaces[identifier] = Switch::Interface::PortChannel.new(identifier, interface)
          end

        else
          raise StandardError, "unknown interface type: #{type}"
        end
      end
    end

    #def merge
    #  @ethernet_interfaces.each do |port|
    #  end
    #end
  end

  class Interface
    class Ethernet
      attr_accessor :description, :stack_member, :port, :unit, :switchport

      def initialize(identifier, interface)
        @identifier   = identifier
        @description  = interface[:description]
        @stack_member = interface[:stack_member]
        @port         = interface[:port]
        @unit         = interface[:unit]
        @switchport   = Switch::Interface::Attribute::Switchport.new(interface[:switchport]) unless interface[:switchport].nil?
      end

      #def inspect
      #  "stack_member: #{@stack_member}, port: #{@port}, unit: #{@unit}, description: #{@description}, switchport: #{@switchport.inspect}".chomp
      #end

      #def mode
      #  "mode: #{@mode} " unless @mode.nil?
      #end
    end

    #
    # Describe a VLAN interface:
    # 
    # * desciption
    # * vlan
    #
    class Vlan
      attr_reader :vlan, :description

      def initialize(identifier, interface)
        @identifier  = identifier
        @vlan        = interface[:vlan]
        @description = interface[:description]
      end

      #def inspect
      #  "vlan: #{@vlan}, description: #{@description}"
      #end
    end

    class PortChannel
      attr_reader :description, :channel, :switchport

      def initialize(identifier, interface)
        @identifier  = identifier
        @description = interface[:description]
        @channel     = interface[:channel]
        @switchport  = Switch::Interface::Attribute::Switchport.new(interface[:switchport])
      end

      #def description
      #  "description: #{@description}" unless description.nil?
      #end

      #def channel
      #  "channel: #{@channel}" unless channel.nil?
      #end

#      def inspect
#        "description: #{@description}, channel: #{@channel}, switchport: #{@switchport.inspect}"
#      end
    end

    module Attribute
      class Switchport
        attr_reader :mode, :vlans

        def initialize(switchport)
          @mode    = switchport[:mode]
          unless switchport[:vlans].nil?
            unless switchport[:vlans][:add].nil?
              @added = Switch::Interface::Attribute::Vlans.new(switchport[:vlans][:add])
            end
            unless switchport[:vlans][:remove].nil?
              @removed = Switch::Interface::Attribute::Vlans.new(switchport[:vlans][:remove])
            end
          end
        end
      end

#        def mode
#          "mode: #{@mode}" unless @mode.nil?
#        end
#
#        def inspect
#          "[mode: #{@mode}, #{@vlans.inspect}]" unless @vlans.nil? and @mode.nil?
#        end

      class Vlans
        attr_accessor :vlans

        def initialize(vlans)
          @vlans = {}

          vlans.each do |vlan, macs|
            @vlans[vlan] = Switch::Interface::Attribute::Vlan.new(vlan, macs)
          end
        end
      end

      class Vlan
        attr_accessor :vlan, :macs

        def initialize(vlan, macs)
          @vlan = vlan
          @macs = macs
        end
      end

#<Switch::Bridge::Entry:0x00000001c2cbe8 @identifier="1_g28", @port="g", @unit="2", @switch_member="1", @vlans=#<Switch::Interface::Attribute::Vlan:0x00000001c2cbc0 @vlans={"313"=>{"0050.5603.0064"=>"Dynamic", "0050.5603.0065"=>"Dynamic", "0050.5603.0066"=>"Dynamic", "0050.5603.0068"=>"Dynamic", "0050.5603.006A"=>"Dynamic"}}>


#      class Vlans
#        attr_reader :add, :remove
#
#        def initialize(vlans)
#        end
#
#        def foo
#          add.each do |vlan|
#          end
#        end

#        def inspect
#          "vlans: add: '#{add}', remove: '#{remove}'"
#          "(vlans: #{[self.add, self.remove].join(', ')})" unless @add.nil? and @remove.nil?
#        end

#        def add
#          "add: [#{@add.join(', ')}]" unless @add.nil?
#        end
#
#        def remove
#          "remove: [#{@remove.join(', ')}]" unless @remove.nil?
#        end
#      end
    end
  end
end
