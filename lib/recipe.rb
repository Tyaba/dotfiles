include_recipe 'recipe_helper'

case node[:platform]
when 'ubuntu', 'debian'
  node.reverse_merge!(
    user: ENV['SUDO_USER'] || ENV['USER'],
    codename: run_command('lsb_release -cs').stdout.strip,
  )
else
  node.reverse_merge!(
    user: ENV['SUDO_USER'] || ENV['USER'],
  )
end

include_role node[:platform]
