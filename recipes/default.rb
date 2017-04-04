#
# Cookbook Name:: borg
# Recipe:: default
#
# Copyright 2016, Jason Kinnard
#

case node["os"]
when "linux"
  include_recipe "borg::linux"
end
