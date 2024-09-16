case node[:platform]
when 'darwin'
    execute "install android studio" do
        command "brew install --cask android-studio"
        not_if "brew list --cask | grep -q '^android-studio$'"
    end
else
    raise NotImplementedError
end
