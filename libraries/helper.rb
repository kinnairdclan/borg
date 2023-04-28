module BorgChef
  module Helpers

    include Chef::Mixin::ShellOut

    def construct_arg(name, arg)
      case arg
      when String, Fixnum
        " --#{name} #{arg}"
      when TrueClass or FalseClass
        " --#{name}"
      when Array
        arg.map { |a| " --#{name} #{a}"}.join
      when NilClass
        ""
      else
        ""
      end
    end

    def assemble_universal_args
      args = [
        construct_arg("lock-wait", lock_wait),
        construct_arg("show-rc", show_rc),
        construct_arg("no-files-cache", no_files_cache),
        construct_arg("umask", umask),
        construct_arg("remote-path", remote_path)
      ].compact.join
    
      args += " --#{log_level}" if defined?(log_level) && ["critical", "error", "warning", "info", "debug", "v", "verbose"].include?(log_level)
      
      args
    end


  end
end
