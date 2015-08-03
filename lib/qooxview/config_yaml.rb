$config = {} if not defined? $config
$name = $0.match(/.*?([^\/]*).rb/)[1]

# Searches for name in every directory from 'dir' towards the root and
# returns the found filename.
# If nothing is found, it returns nil
# If 'dir' is nil, the directory of the running script is taken
def search_up(name, dir = nil)
  dir ||= File.realdirpath(File.dirname($0))
  return File.join(dir, name) if File.exists?(File.join(dir, name))
  return nil if File.realdirpath(dir) == '/'
  search_up(name, File.realdirpath(File.join(dir, '..')))
end

def load_config(path=nil)
  #dputs_func
  if conf = search_up("#{$name.downcase}.conf", path)
    dputs(3) { "Found configuration-file #{conf}" }
    IO.readlines(conf).each { |l|
      dputs(4) { "Reading line #{l}" }
      next if l =~ /(^#|^\s*$)/
      name, value =
          case l
            when /^\s*(.*?)="(.*?)".*$/
              [$1, $2]
            when /^\s*(.*?)=([^\s#]*)/
              [$1, $2]
            else
              [nil, nil]
          end
      if name && value
        dputs(3) { "Writing configuration _#{$1}_ = _#{$2}_" }
        $config[$1.to_sym] = $2
      end
    }
  end
  if defined?(CONFIG_FILE)
    file = path ? File.join(path, CONFIG_FILE) : CONFIG_FILE
    if FileTest.exist?(file)
      File.open(file) { |f| $config.merge!(YAML::load(f).to_sym) }
    end
  end
end

def get_config(default, *path)
  get_config_rec(path, default)
end

def get_config_rec(path, default, config = $config)
  if path.length == 0
    return config
  else
    key = path.shift.to_sym
    if config and config.has_key? key
      return get_config_rec(path, default, config[key])
    else
      return default
    end
  end
end

def set_config(value, *path)
  if path.length == 0
    dputs(0) { "Error: empty path in #{caller.inspect}" }
  else
    config = $config
    path[0...-1].each { |p|
      dputs(4) { "Doing level #{p}" }
      if !config.has_key? p
        config[p] = {}
        dputs(4) { "Added Hash to #{p} - #{$config.inspect}" }
      end
      config = config[p]
    }
    config[path.last] = value
    dputs(4) { "config is #{config.inspect} - $config is #{$config.inspect}" }
  end
end

defined?(CONFIG_FILE) and dputs(2) { "config is #{$config.inspect} - file is #{CONFIG_FILE}" }
