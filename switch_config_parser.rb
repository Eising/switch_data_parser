#!/usr/bin/env ruby

class SwitchConfigParser
  def initialize(io, debug = false)
    @io         = io
    @debug      = debug
    @interfaces = {}
  end

  def parse_config
    @io.each do |line|

      case line

      when /^$/ then
        next

      when /^!/ then
        next

      when /interface ethernet/ then
        parse_interface_ethernet(line)
        @in_interface_block = 'ethernet'
        next

      when /interface vlan/ then
        parse_interface_vlan(line)
        @in_interface_block = 'vlan'
        next

      when /^exit/ then
        @interfaces.merge @current_interface unless @current_interface.nil?
        @in_interface_block = false
        next

      end

      case @in_interface_block
      when 'ethernet' then parse_interface_ethernet(line)
      when 'vlan'     then parse_interface_vlan(line)
      else
        puts "unrecognised line: #{line}" if @debug
      end
    end
  end

  def get_interfaces
    @interfaces
  end

  private

  # FIXME: make sure range is correct..
  def parse_vlan_line(line)
    ranges = line.split(',')

    vlans = ranges.each do |range|
      if range =~ /-/
        a = range.split('-')
        range = (a[0]..a[1]).to_a
      end
      range
    end
    vlans.flatten
  end

  def parse_interface_vlan(line)
    case line
    when /interface vlan/
      @identifier = line.gsub(' ', '_').gsub('/', '_').chomp
      @interfaces[@identifier] = {}
    when /name/
      @interfaces[@identifier][:description] = line.gsub(/name "/, '').chomp.chomp('"')
    end
  end

  def parse_interface_ethernet(line)
    case line
    when /interface ethernet/

      @identifier = line.gsub(' ', '_').gsub('/', '_').chomp

      @interfaces[@identifier] = {
        :unit => line.split[2].split('/')[0],
        :port => line.split[2].split('/')[1].gsub(/[a-z]*/, ''),
        :type => line.split[2].split('/')[1].gsub(/[0-9]*/, ''),
      }

    when /description/
      @interfaces[@identifier][:description] = line.gsub(/description '/, '').chomp.chomp('\'')

    when /channel-group/
      @interfaces[@identifier][:channel_group] = {
        :id   => line.split[1],
        :mode => line.split[3],
      }

    when /switchport/

      @interfaces[@identifier][:switchport] ||= {}

      case line
      when /access/
        @interfaces[@identifier][:switchport][:mode] = 'access'

      when /mode trunk/
        @interfaces[@identifier][:switchport][:mode] = 'trunk'

      when /general/
        @interfaces[@identifier][:switchport][:mode] = 'general'

      when /access vlan/
        @interfaces[@identifier][:switchport][:vlans] ||= {}
        @interfaces[@identifier][:switchport][:vlans].merge({ :add => parse_vlan_line(line) })

      when /trunk allowed vlan add/
        @interfaces[@identifier][:switchport][:vlans] ||= {}
        @interfaces[@identifier][:switchport][:vlans].merge({ :add => parse_vlan_line(line) })

      when /trunk allowed vlan remove/
        @interfaces[@identifier][:switchport][:vlans] ||= {}
        @interfaces[@identifier][:switchport][:vlans].merge({ :remove => parse_vlan_line(line) })

      when /general allowed vlan add/
        @interfaces[@identifier][:switchport][:vlans] ||= {}
        @interfaces[@identifier][:switchport][:vlans].merge({ :add => parse_vlan_line(line) })

      when /general allowed vlan remove/
        @interfaces[@identifier][:switchport][:vlans] ||= {}
        @interfaces[@identifier][:switchport][:vlans].merge({ :remove => parse_vlan_line(line) })

      when /general acceptable-frame-type/
        @interfaces[@identifier][:switchport][:acceptable_frame_type] = line.split[-1]
      end
    end
  end
end
