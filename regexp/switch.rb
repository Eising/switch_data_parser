#!/usr/bin/env ruby

class Switch
  class Bridge
    class Table
      def initialize(table)
        @table = table
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
        @vlans         = entry[:vlan]
      end
    end
  end

  class Config
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

    def get_ethernet_interfaces
      @ethernet_interfaces
    end

    def get_vlan_interfaces
      @vlan_interfaces
    end

    def get_port_channel_interfaces
      @port_channel_interfaces
    end
  end

  class Interface
    class Ethernet
      def initialize(identifier, interface)
        @identifier   = identifier
        @interface    = interface
        @description  = interface[:description]
        @stack_member = interface[:stack_member]
        @port         = interface[:port]
        @unit         = interface[:unit]
        @switchport   = Switch::Interface::Attribute::Switchport.new(interface[:switchport]) unless interface[:switchport].nil?
      end

      def inspect
        "stack_member: #{@stack_member}, port: #{@port}, unit: #{@unit}, description: #{@description}, switchport: #{@switchport.inspect}".chomp
      end

      def mode
        "mode: #{@mode} " unless @mode.nil?
      end
    end

    class Vlan
      def initialize(identifier, interface)
        @identifier  = identifier
        @interface   = interface
        @vlan        = interface[:vlan]
        @description = interface[:description]
      end

      def inspect
        "vlan: #{@vlan}, description: #{@description}"
      end
    end

    class PortChannel
      def initialize(identifier, interface)
        @identifier  = identifier
        @interface   = interface
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

      def inspect
        "description: #{@description}, channel: #{@channel}, switchport: #{@switchport.inspect}"
      end
    end

    module Attribute
      class Switchport
        def initialize(switchport)
          @switchport = switchport
          @mode       = switchport[:mode]
          @vlans      = Switch::Interface::Attribute::Vlans.new(switchport[:vlans])
        end

        def mode
          "mode: #{@mode}" unless @mode.nil?
        end

        def inspect
          "[mode: #{@mode}, #{@vlans.inspect}]" unless @vlans.nil? and @mode.nil?
        end
      end

      class Vlans
        def initialize(vlans)
          @vlans  = vlans
          @add    = vlans[:add]
          @remove = vlans[:remove]
        end

        def inspect
          "(vlans: #{[self.add, self.remove].join(', ')})" unless @add.nil? and @remove.nil?
        end

        def add
          "add: [#{@add.join(', ')}]" unless @add.nil?
        end

        def remove
          "remove: [#{@remove.join(', ')}]" unless @remove.nil?
        end
      end
    end
  end
end
