case node[:platform]
when 'darwin'
    package "k6"
when 'ubuntu', 'debian'
    package 'gnupg'
    package 'curl'
    execute "install k6" do
        command <<-EOF
            sudo rm -f /usr/share/keyrings/k6-archive-keyring.gpg
            curl -fsSL https://dl.k6.io/key.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/k6-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
            sudo apt-get update
            sudo apt-get install k6 -y
        EOF
        not_if "dpkg -s k6"
    end
else
    raise "Not supported platform: #{node[:platform]}"
end
