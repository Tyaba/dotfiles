case node[:platform]
when "darwin"
    command "brew install --cask obs" do
        not_if "test -d /Applications/OBS.app"
end
else
    raise NotImplementedError
end
