#!/usr/bin/env ruby

module SwitchDataParser
  module Regexp
    module Config
      def self.setup_hash(type, line)
        @config[:interface] ||= {}
        @config[:interface][type] ||= {}

        identifier = line.gsub(/ /, '_').gsub(/-/, '_').gsub(/\//, '_').chomp

        @config[:interface][type][identifier] ||= {}
        @config[:interface][type][identifier]
      end

      def self.parse(io, debug = false)
        @debug  = debug
        @config = {}

        io.each do |line|

          case line

          when /^$/ then
            next

          when /^!/ then
            next

          when /interface ethernet/ then
            @interface_ethernet = self.setup_hash(:ethernet, line)
            @in_interface_block = :ethernet
            self.parse_interface_ethernet(line)
            next

          when /interface vlan/ then
            @interface_vlan = self.setup_hash(:vlan, line)
            @in_interface_block = :vlan
            self.parse_interface_vlan(line)
            next

          when /interface port-channel/ then
            @interface_port_channel = self.setup_hash(:port_channel, line)
            @in_interface_block = :port_channel
            self.parse_interface_port_channel(line)
            next

          when /^exit/ then
            @in_interface_block = false
            next

          end

          case @in_interface_block
          when :ethernet     then self.parse_interface_ethernet(line)
          when :vlan         then self.parse_interface_vlan(line)
          when :port_channel then self.parse_interface_port_channel(line)
          else
            puts "unrecognised line: #{line}" if @debug
          end
        end

        @config
      end

      private

      def self.parse_vlan_line(line)
        if line =~ /switchport access vlan/
          ranges = line.split(' ')[3].split(',')
        else
          ranges = line.split(' ')[5].split(',')
        end

        vlans = ranges.map do |range|
          if range =~ /-/
            a = range.split('-')
            range = (a[0]..a[1]).to_a
          end
          range
        end

        vlan_hash = {}

        vlans.flatten.each { |vlan| vlan_hash[vlan.to_i] = {} unless vlan.nil? }

        vlan_hash
        #vlans.flatten
      end

      def self.parse_switchport(line, config)
        switchport = config[:switchport] ||= {}

        case line
        when /switchport access vlan/
          switchport[:mode] = 'access'
          switchport[:vlans] ||= {}
          switchport[:vlans][:add] = self.parse_vlan_line(line)

        when /switchport mode trunk/
          switchport[:mode] ||= {}
          switchport[:mode] = 'trunk'

        when /switchport mode general/
          switchport[:mode] ||= {}
          switchport[:mode] = 'general'

        when /switchport trunk allowed vlan add/
          switchport[:vlans] ||= {}
          switchport[:vlans][:add] = self.parse_vlan_line(line)

        when /switchport trunk allowed vlan remove/
          switchport[:vlans] ||= {}
          switchport[:vlans][:remove] = self.parse_vlan_line(line)

        when /switchport general allowed vlan add/
          switchport[:vlans] ||= {}
          switchport[:vlans][:add] = self.parse_vlan_line(line)

        when /switchport general allowed vlan remove/
          switchport[:vlans] ||= {}
          switchport[:vlans][:remove] = self.parse_vlan_line(line)

        when /switchport general acceptable-frame-type/
          switchport[:acceptable_frame_type] = line.split[-1]

        else
          puts "unrecognised line: #{line}" if @debug
        end
      end

      def self.parse_interface_vlan(line)
        case line

        when /interface vlan/
          @interface_vlan.merge!({ :vlan => line.split[2].to_i })

        when /name/
          @interface_vlan[:description] = line.gsub(/name "/, '').chomp.chomp('"')

        else
          puts "unrecognised line: #{line}" if @debug
        end
      end

      def self.parse_interface_ethernet(line)
        case line

        when /interface ethernet/
          @interface_ethernet[:stack_member] = line.split[2].split('/')[0].to_i
          @interface_ethernet[:port] = line.split[2].split('/')[1].gsub(/[a-z]*/, '').to_i
          @interface_ethernet[:unit] = line.split[2].split('/')[1].gsub(/[0-9]*/, '')

        when /description/
          @interface_ethernet[:description] = line.gsub(/description '/, '').chomp.chomp('\'')

        when /channel-group/
          @interface_ethernet[:channel_group] = {
            :id   => line.split[1],
            :mode => line.split[3],
          }

        when /switchport/
          parse_switchport(line, @interface_ethernet)

        else
          puts "unrecognised line: #{line}" if @debug
        end
      end

      def self.parse_interface_port_channel(line)
        case line

        when /interface port-channel/
          @interface_port_channel.merge!({ :channel => line.split[2] })

        when /description/
          @interface_port_channel[:description] = line.gsub(/description '/, '').chomp.chomp('\'')

        when /switchport/
          parse_switchport(line, @interface_port_channel)

        else
          puts "unrecognised line: #{line}" if @debug
        end
      end
    end
  end
end



