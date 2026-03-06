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
