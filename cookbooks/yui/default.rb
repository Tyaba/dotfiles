case node[:platform]
when 'darwin'
  plist_name = 'com.tepein.yui-proxy'
  plist_path = "#{ENV['HOME']}/Library/LaunchAgents/#{plist_name}.plist"
  gcloud_path = '/opt/homebrew/bin/gcloud'

  template plist_path do
    source File.join(File.dirname(__FILE__), 'yui-proxy.plist.erb')
    user node[:user]
    mode '0644'
    variables(
      label: plist_name,
      gcloud: gcloud_path,
      port: 52981,
    )
  end

  execute "launchctl load #{plist_path}" do
    not_if "launchctl list | grep #{plist_name}"
  end
else
  service_path = "#{ENV['HOME']}/.config/systemd/user/yui-proxy.service"

  remote_file service_path do
    source File.join(File.dirname(__FILE__), 'files/yui-proxy.service')
    owner node[:user]
    mode '0644'
  end

  link "#{ENV['HOME']}/.config/systemd/user/default.target.wants/yui-proxy.service" do
    to service_path
  end

  user_service 'yui-proxy' do
    action :start
  end
end
