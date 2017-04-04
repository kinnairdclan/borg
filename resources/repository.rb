#Universal options
property :remote_path, String
property :log_level, String
property :lock_wait, Fixnum
property :show_rc, TrueClass
property :no_files_cache, TrueClass
property :umask, Fixnum

#Repository options
property :repo_path, String, name_property: true
property :passphrase, String
property :user, String
property :working_directory, String
property :borg_cache_dir, String
property :borg_rsh, String

#Repostiory Create options
property :encryption, String

#Repository Delete options
property :cache_only, TrueClass
property :save_space, TrueClass

include BorgChef::Helpers

action :create do

  user = user.nil? ? node["borg"]["backup_user"] : user
  new_resource.user = user

  borg_cache_dir = borg_cache_dir.nil? ? "#{node["etc"]["passwd"][user]["dir"]}/.cache/borg" : borg_cache_dir
  passphrase = passphrase.nil? ? node["borg"]["repository_passphrase"] : passphrase

  borg_rsh = borg_rsh.nil? ? node["borg"]["borg_rsh"] : borg_rsh

  args = assemble_universal_args

  ["none", "keyfile", "repokey"].each do |enc|
    construct_arg("encryption", encryption) if encryption.eql? enc
  end

  execute "borgbackup init of repository #{repo_path}" do
    command "borg init #{args} #{repo_path}"
    user new_resource.user
    environment 'BORG_PASSPHRASE' => passphrase, 
                'BORG_CACHE_DIR' => borg_cache_dir,
                'BORG_RSH' => borg_rsh
    not_if { ::File.exist?(repo_path) && 
           IO.read("#{repo_path}/README") == "This is a Borg repository\n" }
           #The above is pretty lame, but Borg does even less to check for repo existence before erroring out. TODO: make this work for ssh backups!
  end
end
             
action :delete do

  user = user.nil? ? node["borg"]["backup_user"] : user
  new_resource.user = user

  borg_cache_dir = borg_cache_dir.nil? ? "#{node["etc"]["passwd"][user]["dir"]}/.cache/borg" : borg_cache_dir
  passphrase = passphrase.nil? ? node["borg"]["repository_passphrase"] : passphrase

  borg_rsh = borg_rsh.nil? ? node["borg"]["borg_rsh"] : borg_rsh

  args = assemble_universal_args

  args += construct_arg("cache-only", cache_only)
  args += construct_arg("save-space", save_space)

  execute "borgbackup delete of repository #{repo_path}" do
    command "borg delete #{args} #{repo_path}"
    user new_resource.user
    environment 'BORG_PASSPHRASE' => passphrase, 
                'BORG_CACHE_DIR' => borg_cache_dir,
                'BORG_DELETE_I_KNOW_WHAT_I_AM_DOING' => "YES",
                'BORG_RSH' => borg_rsh
    only_if { ::File.exist?(repo_path) && 
            IO.read("#{repo_path}/README") == "This is a Borg repository\n" } #TODO: make this work for ssh backups!
  end
end

