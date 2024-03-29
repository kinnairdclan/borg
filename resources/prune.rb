#Borg universal options
property :remote_path, String
property :log_level, String
property :lock_wait, Fixnum
property :show_rc, TrueClass
property :no_files_cache, TrueClass
property :umask, Fixnum

#Borg prune options
property :repository, String
property :passphrase, String
property :automated, TrueClass
property :dry_run, TrueClass
property :stats, TrueClass
property :keep_within, String
property :keep_hourly, Fixnum
property :keep_daily, Fixnum
property :keep_weekly, Fixnum
property :keep_monthly, Fixnum
property :keep_yearly, Fixnum
property :prefix, String
property :save_space, TrueClass
property :user, String
property :borg_cache_dir, String
property :borg_rsh, String

#Automated prune cron options
property :cron_minute, String
property :cron_hour, String
property :cron_day, String
property :cron_month, String
property :cron_weekday, String
property :time_interval, Symbol
property :mailto, String
property :script, String, default: "/srv/scripts/borg_prune.sh"

include BorgChef::Helpers

action :create do

  user ||= node["borg"]["backup_user"]
  new_resource.user = user

  borg_cache_dir ||= "#{node["etc"]["passwd"][user]["dir"]}/.cache/borg"
  passphrase ||= node["borg"]["repository_passphrase"]
  borg_rsh ||= node["borg"]["borg_rsh"]
  
  prune_args = assemble_universal_args +
  construct_arg("dry-run", dry_run) +
  construct_arg("stats", stats) +
  construct_arg("keep-within", keep_within) +
  construct_arg("keep-hourly", keep_hourly) +
  construct_arg("keep-daily", keep_daily) +
  construct_arg("keep-weekly", keep_weekly) +
  construct_arg("keep-monthly", keep_monthly) +
  construct_arg("keep-yearly", keep_yearly) +
  construct_arg("prefix", prefix) +
  construct_arg("save-space", save_space)

  cmd = "borg prune #{prune_args} #{repository}"

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

    cron "automated borg prune of repository #{repository}" do
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

    execute "borg prune of repository #{repository}" do
      command cmd
      user new_resource.user
      environment 'BORG_PASSPHRASE' => passphrase, 
                  'BORG_CACHE_DIR' => borg_cache_dir, 
                  'BORG_RSH' => borg_rsh
    end
  end
end

action :delete do

  if automated

    file "#{script}" do
      action :delete
    end

    directory "#{::File.dirname(script)}" do
      action :delete
    end

    cron "automated borg prune of repository #{repository}" do
      action :delete
      user new_resource.user
    end
  end
end
