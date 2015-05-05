=begin rdoc
:title:QooxView
:main:QooxView.rb
QooxView - a nice interface to use QooxDoo in Ruby, following the MVC-model.
It is split in a *backend*, containing the _model_ and _controller_-part (and some
of the _view_), written in Ruby, and the *frontend*, handling the main part of the
_view_, written in JavaScript, using QooxDoo.

*Backend* with logic, including
- Entities for logical blocks (the _model_)
- View for how to display the blocks (part of the _view_ and the _controller_)
*Frontend*, holding all code to work with QooxDoo and display the _view_, linked
to the Backend using RPC-calls

It is thought to do as much autoconfiguration as possible.

=View s

Thus, the most simple example is the following:

require 'QooxView.rb'

class Welcome < View
def initialize
show_info :welcome, "hello world"
end
end

QooxView::startWeb

Which does nothing else than show off "hello world". We can add some buttons
and act upon pressing them:

require 'QooxView.rb'

class Welcome < View
def initialize
show_info :welcome, "hello world"
show_button :welt, :world
end
def rpc_button_welt( session, args* )
reply( 'update', { :welcome => "Hallo Welt" } )
end
def rpc_button_world( session, args* )
reply( 'update', { :welcome => "Hello world" } )
end
end

QooxView::startWeb

= Entities

In addition to views, it is possible to have a _model_ of data using the *Entities*.
Copied from ActiveRecords, there is the class in Plural, containing the general
handling (searching, saving, loading) of the data, and the class in the singular,
doing the handling of the special cases on one data.

To make things nicer, a definition of an entity starts out with a list of the elements
found therein, which happen to be used often also in the view-part, so it's a bit
of both:

=== CSV storage

=== LDAP storage

=== SQLite storage

= Other goodies

=== Session handling

=== Permission checking

=== Loading of Entities and View s from directories

=== Configuration-file

A simple YAML-configuration style is supported by default.

=end


if not String.method_defined? :force_encoding
  class String
    def force_encoding(*args)
    end
  end
end

#QOOXVIEW_DIR=%x[ echo $PWD/#{File.dirname(__FILE__)}].chomp
QOOXVIEW_DIR=File.dirname(__FILE__)

require 'yaml'

# I think the rubygems way is just really not useful, sorry
# Before you laugh: yes, I'll gonna learn bundler, soon
Dir[QOOXVIEW_DIR + '/libs/*'].each { |lib|
  library = File.expand_path("#{lib}/lib")
  $: << library
}

require 'active_record'
require 'json'
require 'gettext'

# Looking forward to bundler
$LOAD_PATH.push '../HelperClasses/lib'
require 'helperclasses/dputs'
include HelperClasses::DPuts
extend HelperClasses::DPuts
if not defined?(DEBUG_LVL)
  # Unknown debug-level for recognition in ConfigBase
  DEBUG_LVL = 0.5
end

class Array
  if ![].respond_to? :to_h
    def to_h
      Hash[*self.flatten(1)]
    end
  end

  def to_sym
    collect { |v| v.to_sym }
  end

  def to_sym!
    self.replace(to_sym())
  end

  def to_frontend
    collect { |a| a.to_frontend }.sort { |a, b| a[1]<=>b[1] }
  end

  def to_s
    "[#{join(',')}]"
  end
end

class Object
  def to_frontend
    to_s
  end
end

# Converts all keys of a hash to syms recursively
class Hash
  def to_sym
    ret = {}
    each { |k, v|
      ret[k.to_sym] = v.class == Hash ? v.to_sym : v
    }
    ret
  end

  def to_sym!
    self.replace(to_sym())
  end

  def method_missing(s, *args)
    dputs(4) { "Method is missing: #{s.inspect}" }

    case s.to_s
      when 'to_ary'
        super(s, args)
      when /^_.*[^=]$/
        key = s.to_s.sub(/^_{1,2}/, '').to_sym
        dputs(4) { "Searching for #{s.inspect} -> #{key}" }
        self.class.class_eval <<-RUBY
          def _#{key}(ret = nil)
          self.has_key? :#{key} and return self[:#{key}]
            self.has_key? '#{key}' and return self['#{key}']
            ret ? (self[:#{key}] = {}) : nil
          end

          def __#{key}
            _#{key}(true)
          end
        RUBY
        self.send(s)
      when /^_.*=$/
        key = /^_{1,2}(.*)=$/.match(s.to_s)[1].to_sym
        dputs(4) { "Setting #{s.inspect} -> #{key} to #{args.inspect}" }
        self.has_key? key and return self[key] = args[0]
        self.has_key? key.to_s and return self[key.to_s] = args[0]
        return self[key] = args[0]
      else
        super(s, args)
    end
  end

  #  def to_s
  #    "{#{each{|k,v| k.to_s + ':' + v.to_s + ' '}}}"
  #  end
end


class String
  def pluralize_simple
    case self
      when /y$/
        return self.sub(/y$/, 'ies')
      when /us$/
        return self.sub(/us$/, 'i')
      when /ss$/
        return "#{self}es"
      when /s$/
        return self
      when /man$/
        return self.sub(/an$/, 'men')
      else
        return "#{self}s"
    end
  end

  def to_a
    [self]
  end

  def date_from_web
    Date.from_web(self)
  end

  def cut(reg)
    sub(reg, '')
  end

  def nonempty
    length > 0 ? self : nil
  end
end

class Date
  def to_web
    strftime('%d.%m.%Y')
  end

  def self.from_web(d)
    Date.strptime(d, '%d.%m.%Y')
  end

  def self.from_db(d)
    (d.class == String) ? Date.strptime(d, '%Y-%m-%d') : d
  end
end

class Fixnum
  def separator(sep = ' ')
    self.to_s.tap do |s|
      :go while s.gsub!(/^([^.]*)(\d)(?=(\d{3})+)/, "\\1\\2#{sep}")
    end
  end

  def to_MB(label = 'MB')
    "#{(self / 1_000_000).separator} #{label}"
  end
end

class Bignum
  def separator(sep = ' ')
    self.to_s.tap do |s|
      :go while s.gsub!(/^([^.]*)(\d)(?=(\d{3})+)/, "\\1\\2#{sep}")
    end
  end

  def to_MB(label = 'MB')
    "#{(self / 1_000_000).separator} #{label}"
  end
end


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

require 'RPCQooxdoo'
require 'Entity'
require 'View'
require 'getoptlong'
require 'gettext'
require 'gettext/tools/msgfmt'
require 'gettext/tools/msgmerge'
require 'gettext/tools/xgettext'
Dir.glob(__dir__+'/Helpers/*').each { |f|
  require f
}

$qooxview_cmds = []

module QooxView
  def self.do_opts(dir_entities, dir_views)
    opts = GetoptLong.new(
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--i18n', '-t', GetoptLong::OPTIONAL_ARGUMENT],
        ['--po', '-p', GetoptLong::NO_ARGUMENT],
        ['--archive', '-a', GetoptLong::OPTIONAL_ARGUMENT]
    )
    opts.each { |o, a|
      case o
        when '--help'
          puts "Usage: #{$0} [-t] [--help]"
          puts "\t-t [lang]\tUpdate translations - takes an optional language-argument"
          puts "\t-p\tCreate .mo-files"
          puts "\t--help\tShow this help"
          raise 'PrintHelp'
        when '--i18n'
          potfile = "po/#{$name}.pot"
          %x[ mkdir -p po; rm -f #{potfile} ]
          paths = ["#{dir_entities}/*.rb", "#{dir_views}/*.rb", "#{dir_views}/*/*.rb"]
          dputs(2) { "potfile is #{potfile.inspect}, paths is #{paths.collect { |p| Dir[p] }}" }
          #GetText::Tools::XGetText.run( paths.collect{|p| Dir[p] }.flatten.concat( [ "-o", "#{potfile}" ] ) )
          GetText::Tools::XGetText.run(*paths.collect { |p| Dir[p] }.concat(
                                           %W(-o #{potfile})).flatten)
          if a.length > 0
            pofile = "po/#{$name}-#{a}.po"
            if File.exists? pofile
              %x[ mv #{pofile} #{pofile}.tmp ]
              #%x[ msgmerge #{pofile}.tmp #{potfile} -o #{pofile} ]
              # Should be possible with rmsgmerge, but it didn't work :(
              GetText::Tools::MsgMerge.run("#{pofile}.tmp", potfile, '-o', pofile)
              %x[ rm #{pofile}.tmp ]
            else
              %x[ cp #{potfile} #{pofile} ]
            end
          end
          raise 'UpdatePot'
        when '--po'
          dputs(2) { 'Making mo-files' }
          Dir.glob("po/#{$name}-*.po").each { |po|
            lang = po.match(/.*#{$name}-(.*).po/)[1]
            path = "po/#{lang}/LC_MESSAGES"
            dputs(2) { "Doing po-file #{po} for language #{lang} with path #{path}" }
            if not %x[ mkdir -p #{path}] or not GetText::Tools::MsgFmt.run(po, "-o#{path}/#{$name}.mo")
              dputs(0) { "Error: can't make mo-files, exiting" }
              exit
            end
          }
          raise 'MakeMo'
        when '--archive'
          dputs(2) { 'Going to archive AfriCompta' }
          $qooxview_cmds.push [:archive, a]
      end
    }
  end

  def self.init(dir_entities = nil, dir_views = nil)
    #dputs_func
    if not (Module.constants.index('Test') or Module.constants.index(:Test))
      dputs(2) { 'Doing options' }
      self.do_opts(dir_entities, dir_views)
    end

    # Include all modules in the dir_entities and dir_views
    # directories
    dputs(2) { "Starting init with entities:views = #{[dir_entities, dir_views].join(':')}" }
    [dir_entities, dir_views].each { |d|
      if d
        dputs(2) { "Initializing directory #{d}" }
        Dir[d+'/**/*.rb'].each { |f|
          dputs(3) { "Requiring file #{f}" }
          require(f)
        }
      end
    }

    if not Permission.list.index('default')
      Permission.add('default', '.*')
    end

    dputs(2) { 'Starting RPCQooxdooServices' }
    # We want to load an eventual ConfigBase first, so that other modules can
    # read the configuration
    rpcqooxdoo = RPCQooxdooService.new('Entities.ConfigBase')
    if true
      ConfigBases.init
    else
      Entities.ConfigBases.load
      ConfigBases.singleton
      Entities.ConfigBases.migrate
    end
    # Everything will be loaded just after, so make sure we have everything done
    # when there is a migration
    Entities.save_all

    GetText.bindtextdomain($name, :path => 'po')
    if ConfigBase.locale_force
      dputs(3) { "Forcing locale to #{ConfigBase.locale_force}" }
      GetText.locale = ConfigBase.locale_force
    end
    GetText::TextDomainManager.cached = false

    # Get an instance of all Qooxdoo-services
    rpcqooxdoo.get_services('^Entities.*')
    Entities.load_all
    rpcqooxdoo.get_services('^View.*')

    $qooxview_cmds.each { |qv|
      qv_cmd = qv.class == Array ? qv[0] : qv
      dputs(2) { "Doing #{qv.inspect}" }
      case qv_cmd
        when :archive
          month = qv[1] == '' ? 1 : qv[1]
          dputs(2) { "Archiving with starting month #{month}" }
          Accounts.archive(month)
          exit
      end
    }
  end

  # The main function, used to start it all
  def self.startWeb(port = 3302, duration = nil)
    dputs(2) { "Configuring port for #{port}" }
    # Suppose we've not being initialized when there are no permissions
    if Permission.list.size == 0
      self.init
    end

    # And start the webrick-server
    # First check whether QooxDoo is running in source- or buid-mode
    dir_html = File.exist?(QOOXVIEW_DIR + '/Frontend/build/script/frontend.js') ?
        'build' : 'source'
    dputs(2) { "Directory for Frontend is: #{dir_html}" }

    log_msg('main', 'Starting up')
    if cmd = get_config(false, :startupCmd)
      %x[ #{cmd} ]
    end
    RPCQooxdooHandler.webrick(port, QOOXVIEW_DIR + "/Frontend/#{dir_html}/",
                              duration)
  end
end
