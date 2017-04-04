platform_family = node["platform_family"]
platform = node["platform"]
platform_version = node["platform_version"].to_f
case platform_family
when "debian"
  case platform
  when "debian"

    if platform_version >= 9.0
      package "borgbackup"
   
    elsif platform_version >= 8.0
      apt_repository "jessie-backports" do
        uri "http://ftp.debian.org/debian"
        components ["main"]
        distribution "jessie-backports"
      end
      apt_package "borgbackup" do
        options "-t jessie-backports"
      end
    end

  when "ubuntu"
    if plaform_version >= 16.04
      package "borgbackup"

    elsif platform_version >= 14.04
      lsb_codename = node["lsb_codename"]
      apt_repository "borgbackup_ppa" do
        uri "ppa:costamagnagianfranco/borgbackup"
        components ["main"]
        distribution ( lsb_codename == "wily" ? lsb_codename : "trusty" )
      end
      package "borgbackup"
    end
  end
end

