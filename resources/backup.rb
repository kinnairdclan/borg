#Borg universal options
property :remote_path, String
property :log_level, String
property :lock_wait, Fixnum
property :show_rc, TrueClass
property :no_files_cache, TrueClass
property :umask, Fixnum

#Options for both backup create/delete
property :stats, TrueClass
property :user, String
property :borg_cache_dir, String
property :borg_rsh, String

#Backup create options
property :archive_name, String, default: "`hostname`-`date +%Y-%m-%d`"
property :repository, String, required: true 
property :compression, String
property :backup, Array, required: true
property :passphrase, String
property :automated, TrueClass
property :exclude, Array
property :exclude_from_file, Array
property :exclude_if_file_present, Array
property :keep_tag_files, TrueClass
property :checkpoint_interval, Fixnum
property :one_file_system, TrueClass
property :numeric_owner, TrueClass
property :timestamp, String
property :chunker_params, String
property :ignore_inode, TrueClass
property :read_special, TrueClass
property :dry_run, TrueClass

#Backup delete options
property :cache_only, TrueClass
property :save_space, TrueClass

#Automated backup cron options
property :cron_minute, String
property :cron_hour, String
property :cron_day, String
property :cron_month, String
property :cron_weekday, String
property :time_interval, Symbol
property :mailto, String
property :script, String, default: "/srv/scripts/borg_backup.sh"

include BorgChef::Helpers

action :create do

  user ||= node["borg"]["backup_user"]
  new_resource.user = user

  borg_cache_dir ||= "#{node["etc"]["passwd"][user]["dir"]}/.cache/borg"
  passphrase ||= node["borg"]["repository_passphrase"]
  borg_rsh ||= node["borg"]["borg_rsh"]
  
  create_args = assemble_universal_args +
  construct_arg("compression", compression) +
  construct_arg("exclude", exclude) +
  construct_arg("exclude-from", exclude_from_file) +
  construct_arg("exclude-if-file-present", exclude_if_file_present) +
  construct_arg("stats", stats) +
  construct_arg("keep-tag-files", keep_tag_files) +
  construct_arg("checkpoint-interval", checkpoint_interval) +
  construct_arg("one-file-system", one_file_system) +
  construct_arg("numeric-owner", numeric_owner) +
  construct_arg("timestamp", timestamp) +
  construct_arg("chunker-params", chunker_params) +
  construct_arg("ignore-inode", ignore_inode) +
  construct_arg("read-special", read_special) +
  construct_arg("dry-run", dry_run)

  backup_list = backup.join(" ")

  cmd = "borg create #{create_args} #{repository}::#{archive_name} #{backup_list}"

  if automated

    cmd.prepend("BORG_PASSPHRASE=#{passphrase} ") if passphrase
    cmd.prepend("BORG_RSH=#{borg_rsh} ") if borg_rsh
    cmd.prepend("BORG_CACHE_DIR=#{borg_cache_dir} ") if borg_cache_dir

    directory "#{::File.dirname(script)}" do
      action :create
      recursive true
      owner user
      group user
    end

    file "#{script}" do
      content "#!/bin/bash\n" + cmd
      action :create
      owner user
      group user
      mode "700"
    end

    cron "automated borg backup to repository #{repository}" do
      minute  cron_minute
      hour cron_hour
      day cron_day
      month cron_month
      weekday cron_weekday
      time time_interval
      command script
      mailto new_resource.mailto
      user new_resource.user
    end

  else

    execute "borg backup of archive #{archive} to repository #{repository}" do
      command cmd
      user new_resource.user
      environment 'BORG_PASSPHRASE' => passphrase, 
                  'BORG_CACHE_DIR' => borg_cache_dir,
                  'BORG_RSH' => borg_rsh
    end
  end
end

action :delete do

  user ||= node["borg"]["backup_user"]
  new_resource.user = user

  borg_cache_dir ||= "#{node["etc"]["passwd"][user]["dir"]}/.cache/borg"
  passphrase ||= node["borg"]["repository_passphrase"]
  borg_rsh ||= node["borg"]["borg_rsh"]

  if automated

    file "#{script}" do
      action :delete
    end

    directory "#{::File.dirname(script)}" do
      action :delete
      recursive true
    end

    cron "automated borg backup to repository #{repository}" do
      action :delete
      user new_resource.user
    end

  else

    delete_args = assemble_universal_args +
    construct_arg("stats", stats) +
    construct_arg("cache-only", cache_only) +
    construct_arg("save-space", save_space)

    cmd = "borg delete #{delete_args} #{repository}::#{archive_name}"

    execute "borg delete of archive #{archive} from repository #{repository}" do
      command cmd
      user new_resource.user
      environment 'BORG_PASSPHRASE' => passphrase, 
                  'BORG_CACHE_DIR' => borg_cache_dir,
                  'BORG_RSH' => borg_rsh,
                  'BORG_DELETE_I_KNOW_WHAT_I_AM_DOING' => "YES"
    end
  end
end
