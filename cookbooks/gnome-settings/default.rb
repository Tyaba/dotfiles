# GNOME preferences and shortcuts used by the Ubuntu desktop.
execute 'configure gnome settings' do
  command "bash #{File.join(File.dirname(__FILE__), 'files', 'configure.sh')}"
  user node[:user] if node[:user]
end
