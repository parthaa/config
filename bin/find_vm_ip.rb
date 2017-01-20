#!/usr/bin/env ruby
require 'libvirt'
conn = Libvirt::open("qemu:///system")
networks = conn.list_all_networks
puts networks.map {|net| net.dhcp_leases.first["ipaddr"] unless net.dhcp_leases.empty?}.compact
