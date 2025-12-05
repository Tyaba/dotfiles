unless ENV['PATH'].include?("#{ENV['HOME']}/.cargo/bin:")
  MItamae.logger.info('Prepending ~/.cargo/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.cargo/bin:#{ENV['PATH']}"
end

package 'cmake'
package 'pkg-config'
case node[:platform]
when 'darwin'
  package 'openssl'
when 'ubuntu', 'debian'
  package 'libssl-dev'
  package 'libwayland-cursor0'
  package 'libwayland-dev'
  package 'libxcb-render0-dev'
  package 'libxcb-shape0-dev'
  package 'libxcb-xfixes0-dev'
end

case node[:platform]
when 'arch'
  package 'rust'
  package 'cargo'

  include_cookbook 'yaourt'
  yaourt 'rust-src'
else
  local_ruby_block 'install rust' do
    rustc_path = "#{ENV['HOME']}/.cargo/bin/rustc"

    block do
      system("curl https://sh.rustup.rs -sSf | sh -s -- -y")

      until File.exist?(rustc_path)
        sleep 1
      end
    end
    not_if "test -f #{rustc_path}"
  end
  execute 'rustup component add rust-src' do
    not_if 'rustup component list --installed | grep rust-analyzer'
  end
end

case node[:platform]
when 'darwin'
  cargo 'cargo-edit'
  case node[:architecture]
  when 'arm64'
    execute 'ln -s $HOME/.cargo/bin/ /opt/homebrew/opt/rust' do
      not_if 'test -d /opt/homebrew/opt/rust/'
    end
  end
end

execute 'rustup toolchain install nightly' do
  not_if "rustup toolchain list | grep nightly"
end

# update cargo
execute 'update cargo and other rustup components' do
  command 'rustup update'
end

cargo 'cargo-edit'
cargo 'bat'
cargo 'exa'
cargo 'du-dust'
cargo 'bottom'
cargo 'rustfmt'
cargo 'rust-script'
cargo 'cargo-update'
cargo 'cargo-deps'
cargo 'cargo-benchcmp'
cargo 'cargo-expand'
cargo 'cargo-make'
cargo 'hexyl'
cargo 'jless'
cargo 'hyperfine'
cargo 'wasm-pack'
# cargo 'git-delta'

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# cargo-script
alias rust="cargo-script"
EOF
''' do
  not_if 'grep cargo-script ~/.zsh/lib/aliases'
end

