case node[:platform]
when "darwin"
    execute "brew install --cask skype" do
        not_if "test -d /Applications/Skype.app"
    end
else
    raise "This recipe is only supported on macOS"
end