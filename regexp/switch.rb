#!/usr/bin/env ruby
#
# TODO
# * probably should check to make sure all attributes from the config hash
#   has been added to the object so nothing is missed..
#

class Switch

  attr_accessor :config
  attr_accessor :bridge_table

  def load_switch_config(config)
    @config = Switch::Config.new(config)
  end

  def load_bridge_table(config)
    @bridge_table = Switch::Bridge::Table.new(config)
  end

  def merge_bridge_table_entries_with_switch_config
    @config.ethernet_interfaces.each do |identifier, interface|
      if defined?(interface.switchport.added)

        vlans = @bridge_table.find_macs_for_port(interface.stack_member, interface.unit, interface.port)

        next if vlans.nil?

        interface.switchport.added.vlans.each do |vlan, data|
          next if data.nil?
          next if vlans[vlan].nil?
          data.macs = vlans[vlan].macs
        end
      end
    end
  end

  def to_hash
    {
      :config => config.to_hash,
      :bridge_table => bridge_table.to_hash,
    }
  end

  alias_method :inspect, :to_hash
  alias_method :to_s, :to_hash

  # represent the bridge table
  module Bridge
    class Table
      attr_reader :entries

      def initialize(table)
        @table   = table
        @entries = {}

        self.objectify
      end

      def objectify
        @table.each do |identifier, entry|
          @entries[identifier] = Switch::Bridge::Entry.new(identifier, entry)
        end
      end

      def find_macs_for_port(stack_member, unit, port)
        entries.each do |identifier, entry|
          if entry.stack_member == stack_member and entry.unit == unit and entry.port == port
            return entry.vlans.vlans
          end
        end
        return
      end

      def to_hash
        {
          :entries => @entries.to_hash
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end

    class Entry
      attr_reader :identifier, :port, :unit, :stack_member, :vlans

      def initialize(identifier, entry)
        @identifier    = identifier
        @port          = entry[:port]
        @unit          = entry[:unit]
        @stack_member  = entry[:stack_member]
        @vlans         = Switch::Attribute::Vlans.new(entry[:vlans]) unless entry[:vlans].nil?
      end
    end

    def to_hash
      {
        :identifier => identifier,
        :vlans => vlans,
      }
    end

    alias_method :inspect, :to_hash
    alias_method :to_s, :to_hash
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

    def to_hash
      {
        :ethernet_interfaces => @ethernet_interfaces.to_hash,
        :vlan_interfaces => @vlan_interfaces.to_hash,
        :port_channel_interfaces => @port_channel_interfaces.to_hash
      }
    end

    alias_method :inspect, :to_hash
    alias_method :to_s, :to_hash
  end

  # shared attributes between configs, interfaces and interface attributes
  module Attribute
    class Vlans
      attr_accessor :vlans

      def initialize(vlans)
        @vlans = {}

        vlans.each do |vlan, macs|
          @vlans[vlan] = Switch::Attribute::Vlan.new(vlan, macs)
        end
      end

      def each
        @vlans.each { |x,y | yield x, y }
      end

      def to_hash
        {
          :vlans => vlans.to_hash
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end

    class Vlan
      attr_accessor :vlan, :macs

      def initialize(vlan, macs)
        @vlan = vlan
        @macs = macs
      end

      def to_hash
        {
          :vlan => vlan,
          :macs => macs.to_hash,
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end
  end

  # represent interface types
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

      def to_hash
        {
          :identifier => @identifier,
          :description => @description,
          :stack_member => @stack_member,
          :port => @port,
          :unit => @unit,
          :switchport => @switchport,
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end

    class Vlan
      attr_reader :identifier, :vlan, :description

      def initialize(identifier, interface)
        @identifier  = identifier
        @vlan        = interface[:vlan]
        @description = interface[:description]
      end

      def to_hash
        {
          :identifier => identifier,
          :description => description,
          :vlan => vlan
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end

    class PortChannel
      attr_reader :identifier, :description, :channel, :switchport

      def initialize(identifier, interface)
        @identifier  = identifier
        @description = interface[:description]
        @channel     = interface[:channel]
        @switchport  = Switch::Interface::Attribute::Switchport.new(interface[:switchport])
      end

      def to_hash
        {
          :identifier => identifier,
          :description => description,
          :channel => channel,
          :switchport => switchport.to_hash,
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end

    # interface attributes
    module Attribute
      class Switchport
        attr_reader :mode, :added, :removed, :acceptable_frame_type

        def initialize(switchport)
          @mode    = switchport[:mode]
          unless switchport[:vlans].nil?
            unless switchport[:vlans][:add].nil?
              @added = Switch::Attribute::Vlans.new(switchport[:vlans][:add])
            end
            unless switchport[:vlans][:remove].nil?
              @removed = Switch::Attribute::Vlans.new(switchport[:vlans][:remove])
            end
          end

          @acceptable_frame_type = switchport[:acceptable_frame_type]
        end

        def to_hash
          {
            :mode => mode,
            :added => added.to_hash,
            :removed => removed,
            :acceptable_frame_type => acceptable_frame_type,
          }
        end

        alias_method :inspect, :to_hash
        alias_method :to_s, :to_hash
      end
    end
  end
end
