case node[:platform]
when 'darwin'
  package 'google-cloud-sdk'
else
  execute 'curl https://sdk.cloud.google.com > tmp/gcloud_install.sh && bash tmp/gcloud_install.sh --disable-prompts --install-dir $HOME/bin' do
    not_if 'ls $HOME/bin/google-cloud-sdk'
  end
end

case `uname -m`
when 'x86_64'
  platform = `uname`.lower
  github_binary "cloud_sql_proxy" do
    raw_url "https://storage.googleapis.com/cloudsql-proxy/v1.28.0/cloud_sql_proxy.#{platform}.amd64"
    not_if "which cloud_sql_proxy"
  end
end
