case node[:platform]
when 'ubuntu', 'debian'
  package 'pulseaudio-utils'
end
