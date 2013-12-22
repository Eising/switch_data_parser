#!/usr/bin/env ruby

class SwitchConfigParser
  def initialize(io, debug = false)
    @io     = io
    @debug  = debug
    @config = {}
  end

  def setup_hash(type, line)
    @config[:interface] ||= {}
    @config[:interface][type] ||= {}
    identifier = line.gsub(/ /, '_').gsub(/-/, '_').gsub(/\//, '_').chomp
    @config[:interface][type][identifier] ||= {}
    @config[:interface][type][identifier]
  end

  def parse_config

    @io.each do |line|

      case line

      when /^$/ then
        next

      when /^!/ then
        next

      when /interface ethernet/ then
        @interface_ethernet = setup_hash(:ethernet, line)
        @in_interface_block = :ethernet
        parse_interface_ethernet(line)
        next

      when /interface vlan/ then
        @interface_vlan = setup_hash(:vlan, line)
        @in_interface_block = :vlan
        parse_interface_vlan(line)
        next

      when /interface port-channel/ then
        @interface_port_channel = setup_hash(:port_channel, line)
        @in_interface_block = :port_channel
        parse_interface_port_channel(line)
        next

      when /^exit/ then
        @in_interface_block = false
        next

      end

      case @in_interface_block
      when :ethernet     then parse_interface_ethernet(line)
      when :vlan         then parse_interface_vlan(line)
      when :port_channel then parse_interface_port_channel(line)
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

    #vlan_hash = {}

    #vlans.flatten.each { |vlan| vlan_hash[vlan] = {} unless vlan.nil? }

    #vlan_hash
    vlans.flatten
  end

  def parse_switchport(line, config)
    switchport = config[:switchport] ||= {}

    case line
    when /switchport access vlan/
      switchport[:mode] = 'access'
      switchport[:vlans] ||= {}
      switchport[:vlans][:add] = parse_vlan_line(line)

    when /switchport mode trunk/
      switchport[:mode] ||= {}
      switchport[:mode] = 'trunk'

    when /switchport mode general/
      switchport[:mode] ||= {}
      switchport[:mode] = 'general'

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
  end

  def parse_interface_vlan(line)
    case line

    when /interface vlan/
      @interface_vlan.merge!({ :vlan => line.split[2] })

    when /name/
      @interface_vlan[:description] = line.gsub(/name "/, '').chomp.chomp('"')

    else
      puts "unrecognised line: #{line}" if @debug
    end
  end

  def parse_interface_ethernet(line)
    case line

    when /interface ethernet/
      @interface_ethernet[:unit] = line.split[2].split('/')[0]
      @interface_ethernet[:unit] = line.split[2].split('/')[1].gsub(/[a-z]*/, '')
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

  def parse_interface_port_channel(line)
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
