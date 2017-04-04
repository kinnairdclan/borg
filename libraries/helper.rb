module BorgChef
  module Helpers

    include Chef::Mixin::ShellOut

    def construct_arg(name, arg)
      if (arg.class == String) or (arg.class == Fixnum)
        " --#{name} #{arg}"
      elsif (arg.class == TrueClass) or (arg.class == FalseClass)
        " --#{name}" if arg
      elsif arg.class == Array
        out = ""
        arg.each do |index|
          out += " --#{name} #{index}"
        end
        out
      else
        ""
      end
    end

    def assemble_universal_args
      args = ""
      ["critical", "error", "warning", "info", "debug", "v", "verbose"].each do |lvl|
        args = " --#{log_level}" if (defined? log_level and log_level.eql? lvl)
      end
      args += construct_arg("lock-wait", lock_wait) if defined? lock_wait 
      args += construct_arg("show-rc", show_rc) if defined? show_rc
      args += construct_arg("no-files-cache", no_files_cache) if defined? no_files_cache
      args += construct_arg("umask", umask) if defined? umask
      args += construct_arg("remote-path", remote_path) if defined? remote_path
      args
    end

  end
end
