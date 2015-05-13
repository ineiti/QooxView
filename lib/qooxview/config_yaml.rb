$config = {} if not defined? $config
if defined?(CONFIG_FILE) and FileTest.exist?(CONFIG_FILE)
  File.open(CONFIG_FILE) { |f| $config = YAML::load(f).to_sym }
end
$name = $0.match(/.*?([^\/]*).rb/)[1]

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
