

#QOOXVIEW_DIR=%x[ echo $PWD/#{File.dirname(__FILE__)}].chomp
QOOXVIEW_DIR=File.dirname(__FILE__)

require 'helper_classes/dputs'
include HelperClasses::DPuts
extend HelperClasses::DPuts
if not defined?(DEBUG_LVL)
  # Unknown debug-level for recognition in ConfigBase
  DEBUG_LVL = 0.5
end

require 'yaml'
require 'active_record'
require 'json'
require 'gettext'
require 'qooxview/rpcqooxdoo'
require 'qooxview/entity'
require 'qooxview/view'
require 'qooxview/additions'
require 'qooxview/config_yaml'
require 'getoptlong'
require 'gettext'
require 'gettext/tools/msgfmt'
require 'gettext/tools/msgmerge'
require 'gettext/tools/xgettext'
Dir.glob(__dir__+'/helpers/*').each { |f|
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
    if not (Module.constants.index('Test') or Module.constants.index(:test))
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
    dir_html = File.exist?(QOOXVIEW_DIR + '/frontend/build/script/frontend.js') ?
        'build' : 'source'
    dputs(2) { "Directory for Frontend is: #{dir_html}" }

    log_msg('main', 'Starting up')
    if cmd = get_config(false, :startupCmd)
      %x[ #{cmd} ]
    end
    RPCQooxdooHandler.webrick(port, QOOXVIEW_DIR + "/frontend/#{dir_html}/",
                              duration)
  end
end
