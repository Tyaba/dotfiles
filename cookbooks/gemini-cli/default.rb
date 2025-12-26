case node[:platform]
when 'darwin'
  package 'gemini-cli'
when 'ubuntu', 'debian'
  execute 'npm install -g @google/gemini-cli' do
    not_if 'which gemini'
  end
else
  # do nothing or raise error
end
