execute "cargo install du-dust" do
  not_if "which dust"
end
