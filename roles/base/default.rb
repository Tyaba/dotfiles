if run_command('test -d /etc/systemd', error: false).exit_status == 0
  [
    "#{ENV['HOME']}/.config",
    "#{ENV['HOME']}/.config/systemd",
    "#{ENV['HOME']}/.config/systemd/user",
  ].each do |dir|
    directory dir do
      owner node[:user]
    end
  end
end

root_dir = File.expand_path('../../..', __FILE__)
include_recipe File.join(root_dir, 'lib', 'helper')
include_cookbook 'basic'
