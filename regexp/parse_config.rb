#!/usr/bin/env ruby

class SwitchConfigParser
  def initialize(io, debug = false)
    @io     = io
    @debug  = debug
    @config = {}
  end

  def parse_config

    @io.each do |line|

      case line

      when /^$/ then
        next

      when /^!/ then
        next

      when /interface ethernet/ then

        @config[:interface] ||= {}
        @config[:interface][:ethernet] ||= {}

        parse_interface_ethernet(line)
        @in_interface_block = 'ethernet'
        next

      when /interface vlan/ then

        @config[:interface] ||= {}
        @config[:interface][:vlan] ||= {}

        @in_interface_block = 'vlan'
        next

      when /interface port-channel/ then

        @config[:interface] ||= {}
        @config[:interface][:port_channel] ||= {}
        @identifier = line.gsub(/ /, '_').gsub(/-/, '_').chomp
        @config[:interface][:port_channel][@identifier] ||= {}

        @in_interface_block = 'port_channel'
        next


      when /^exit/ then
        @in_interface_block = false
        next

      end

      case @in_interface_block
      when 'ethernet'     then parse_interface_ethernet(line)
      when 'vlan'         then parse_interface_vlan(line)
      when 'port_channel' then parse_interface_port_channel(line)
      else
        puts "unrecognised line: #{line}" if @debug
      end
    end
  end

  def get_config
    @config
  end

  private

  def parse_vlan_line(line)
    ranges = line.split(' ')[5].split(',')

    vlans = ranges.map do |range|
      if range =~ /-/
        a = range.split('-')
        range = (a[0]..a[1]).to_a
      end
    end

    vlan_hash = {}

    vlans.flatten.each { |vlan| vlan_hash[vlan] = {} unless vlan.nil? }

    vlan_hash
  end

  def parse_interface_vlan(line)
    case line
    when /interface vlan/
      vlan = line.split[2]
      @identifier = line.gsub(' ', '_').gsub('/', '_').chomp
      @config[:interface][:vlan][@identifier] ||= {}
      @config[:interface][:vlan][@identifier].merge!({ :vlan => vlan })
    when /name/
      vlan = line.split[2]
      @identifier = line.gsub(' ', '_').gsub('/', '_').chomp
      @config[:interface][:vlan][@identifier] ||= {}
      @config[:interface][:vlan][@identifier][:description] = line.gsub(/name "/, '').chomp.chomp('"')
    else
      puts "unrecognised line: #{line}" if @debug
    end
  end

  def parse_interface_ethernet(line)
    case line
    when /interface ethernet/

      @identifier = line.gsub(' ', '_').gsub('/', '_').chomp

      @interface_ethernet = @config[:interface][:ethernet][@identifier]

      @interface_ethernet = {
        :unit => line.split[2].split('/')[0],
        :port => line.split[2].split('/')[1].gsub(/[a-z]*/, ''),
        :type => line.split[2].split('/')[1].gsub(/[0-9]*/, ''),
      }

    when /description/
      @interface_ethernet[:description] = line.gsub(/description '/, '').chomp.chomp('\'')

    when /channel-group/
      @interface_ethernet[:channel_group] = {
        :id   => line.split[1],
        :mode => line.split[3],
      }

    when /switchport/
      @interface_ethernet[:switchport] ||= {}

      switchport = @interface_ethernet[:switchport]

      case line
      when /switchport access/
        switchport[:mode] = 'access'

      when /switchport mode trunk/
        switchport[:mode] = 'trunk'

      when /switchport mode general/
        switchport[:mode] = 'general'

      when /switchport access vlan/
        switchport[:vlans] ||= {}
        switchport[:vlans][:add] = parse_vlan_line(line)

      when /switchport trunk allowed vlan add/
        switchport[:vlans] ||= {}
        switchport[:vlans][:add] = parse_vlan_line(line)

      when /switchport trunk allowed vlan remove/
        switchport[:vlans] ||= {}
        switchport[:vlans][:remove] = parse_vlan_line(line)

      when /switchport general allowed vlan add/
        switchport[:vlans] ||= {}
        switchport[:vlans][:add] = parse_vlan_line(line)

      when /switchport general allowed vlan remove/
        switchport[:vlans] ||= {}
        switchport[:vlans][:remove] = parse_vlan_line(line)

      when /switchport general acceptable-frame-type/
        switchport[:acceptable_frame_type] = line.split[-1]
      else
        puts "unrecognised line: #{line}" if @debug
      end
    else
      puts "unrecognised line: #{line}" if @debug
    end
  end

  def parse_interface_port_channel(line)
    case line
    when /interface port-channel/
      channel = line.split[2]
      @config[:interface][:port_channel][@identifier] = { :channel => channel }
    when /description/
      @config[:interface][:port_channel][@identifier][:description] = line.gsub(/description '/, '').chomp.chomp('\'')
    else
      puts "unrecognised line: #{line}" if @debug
    end
  end
end
