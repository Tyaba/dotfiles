root_dir = File.expand_path('../..', __FILE__)

define :dotfile do
  if params[:name].is_a?(String)
    links = { params[:name] => params[:name] }
  else
    links = params[:name]
  end

  links.each do |link_from, link_to|
    directory File.dirname(link_from = File.join(ENV['HOME'], link_from)) do
      user node[:user]
    end

    link link_from do
      to File.join(root_dir, "config/#{link_to}")
      user node[:user]
      force true
    end
  end
end

define :github_binary, raw_url: nil, version: nil, repository: nil, archive: nil, binary_path: nil do
  sudo_prefix = 'sudo ' if ['ubuntu', 'debian', 'darwin'].include?(node[:platform]) else ''
  cmd = params[:name]
  bin_path = "/usr/local/bin/#{cmd}"
  archive = params[:archive]
  url = params[:raw_url] || "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive
    if archive.end_with?('.zip')
      extract = "unzip -o"
    elsif archive.end_with?('.tar.gz')
      extract = "tar xvzf"
    else
      raise "unexpected ext archive: #{archive}"
    end

    execute "curl -fSL -o /tmp/#{archive} #{url}" do
      not_if "test -f #{bin_path}"
    end
    execute "#{extract} /tmp/#{archive}" do
      not_if "test -f #{bin_path}"
      cwd "/tmp"
    end
  else
    execute "curl -fSL -o /tmp/#{cmd} #{url}" do
      not_if "test -f #{bin_path}"
    end
  end
  execute "#{sudo_prefix}mv /tmp/#{params[:binary_path] || cmd} #{bin_path} && #{sudo_prefix}chmod +x #{bin_path}" do
    not_if "test -f #{bin_path}"
  end
end

define :user_service, action: [] do
  name = params[:name]
  Array(params[:action]).each do |action|
    case action
    when :enable
      execute "sudo -E -u #{node[:user]} systemctl --user enable #{name}" do
        not_if "sudo -E -u #{node[:user]} systemctl --user --quiet is-enabled #{name}"
      end
    when :start
      execute "sudo -E -u #{node[:user]} systemctl --user start #{name}" do
        not_if "sudo -E -u #{node[:user]} systemctl --user --quiet is-active #{name}"
      end
    end
  end
end

define :cargo, action: [] do
  name = params[:name]
  execute "cargo install --force --verbose #{name}" do
    not_if %Q[cargo install --list | grep "^#{name}"]
  end
end
