case node[:platform]
when 'darwin'
  execute 'brew install direnv'
else
  raise NotImplementedError
end
