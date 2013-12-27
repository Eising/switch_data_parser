#!/usr/bin/env ruby

class Machines
  attr_accessor :config, :machines

  def initialize(config)
    @config   = config
    @machines = {}

    objectify
  end

  def objectify
    @config.each do |hostname, data|
      @machines[hostname] = Machine.new(data)
    end
  end

  def to_hash
    { :machines => machines }
  end

  def normalize_mac(mac)
    mac.downcase.gsub(/[^0-9a-zA-Z]*/, '')
  end

  def find_machine(mac)
    @machines.each do |hostname, machine|
      machine.interfaces.each do |interface, interface_data|
        #puts "no match: #{hostname}: #{normalize_mac(interface_data.mac_address)} == #{normalize_mac(mac)}"
        if normalize_mac(interface_data.mac_address) == normalize_mac(mac)
          puts "match found: #{hostname}: #{normalize_mac(interface_data.mac_address)} == #{normalize_mac(mac)}"
          puts "interface: #{interface}"
          puts "hostname: #{hostname}"
          #ap machine
        end
      end
    end
  end

  # associate each machine interface MAC address with a switch port
  def combine_data(switches)
    switches
  end

  alias_method :inspect, :to_hash
  alias_method :to_s, :to_hash

  class Machine
    attr_accessor :mac_address, :interfaces

    def initialize(data)
      @data       = data
      @interfaces = {}

      objectify
    end

    def objectify
      @data.each do |interface, data|
        @interfaces[interface] = Interface.new(data)
      end
    end

    def to_hash
      { :interfaces => interfaces }
    end

    alias_method :inspect, :to_hash
    alias_method :to_s, :to_hash

    class Interface
      attr_accessor :mac_address, :member, :active_interface, :ip_addresses, :slaves, :active_in_bond

      def initialize(data)
        @mac_address      = data[:mac_address]
        @member           = data[:member]
        @active_interface = data[:active_interface]
        @ip_addresses     = data[:ip_addresses]
        @slaves           = data[:slaves]
        @active_in_bond   = data[:active_in_bond]
      end

      def to_hash
        {
          :mac_address      => mac_address,
          :member           => member,
          :active_interface => active_interface,
          :ip_addresses     => ip_addresses,
          :slaves           => slaves,
          :active_in_bond   => active_in_bond,
        }
      end

      alias_method :inspect, :to_hash
      alias_method :to_s, :to_hash
    end
  end
end
