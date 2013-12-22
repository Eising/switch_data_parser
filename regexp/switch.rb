#!/usr/bin/env ruby

module Switch
  module Bridge
    class Table
      def initialize(config)
        @config = config
        @interfaces = {}
        self.objectify
      end

      def objectify
        @config.each do |name, interface|
          @interfaces[name] = Switch::Bridge::Interface.new(name, interface)
        end
      end
    end

    class Interface
      attr_reader :name, :port, :unit, :switch_member, :vlans

      def initialize(name, interface)
        @name          = name
        @port          = interface[:port]
        @unit          = interface[:unit]
        @switch_member = interface[:stack_member]
        @vlans         = interface[:vlan]
      end
    end
  end

  module Interface
    class Ethernet
    end
  end
end
