case node[:platform]
when 'darwin'
    execute 'install linear app' do
        command "brew install --cask linear-linear"
        not_if 'test -d /Applications/Linear.app'
    end
else
    raise NotImplementedError
end
