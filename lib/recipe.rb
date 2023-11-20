include_recipe 'recipe_helper'
node.reverse_merge!(
    user: ENV['SUDO_USER'] || ENV['USER'],
    group: ENV['GROUP']
)
case node[:platform]
when 'ubuntu', 'debian'
  node.reverse_merge!(
    codename: run_command('lsb_release -cs').stdout.strip,
  )
when 'darwin'
  # intel macか判定
  # 'x86_64' -> Intel Mac
  # 'arm64' -> M1 Mac
  node.reverse_merge!(
    architecture: `uname -m`.chomp
  )
end

include_role node[:platform]
