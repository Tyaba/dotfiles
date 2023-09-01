include_recipe 'recipe_helper'

node.reverse_merge!(
  user: ENV['SUDO_USER'] || ENV['USER'],
  codename: run_command('lsb_release -cs').stdout.strip,
)

include_role node[:platform]
