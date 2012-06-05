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

=== Logging and undo

The Log-class can do logging and supports an undo-function very easily
=end

require 'yaml'

# I think the rubygems way is just really not useful, sorry
%w( parseconfig-0.5.2 json-1.4.6 net-ldap-0.1.1 activerecord-3.1.1
activesupport-3.1.1 i18n-0.6.0 activemodel-3.1.1 arel-2.2.1
multi_json-1.0.3 sqlite3-1.3.5 rubyzip-0.9.4 docsplit-0.6.0-1
gettext-2.2.0 locale-2.0.5 ).each{|lib|
  $: << File.expand_path(File.dirname(__FILE__)+"/#{lib}/lib")
}

require 'active_record'
require 'json'
require 'DPuts'
require 'gettext'



include DPuts
extend DPuts
if not Module.constants.index "DEBUG_LVL"
DEBUG_LVL = 5
end

# Converts all keys of a hash to syms recursively
class Hash
  def to_sym
    ret = {}
    each{|k,v|
      ret[ k.to_sym ] = v.class == Hash ? v.to_sym : v
    }
    ret
  end

  def to_sym!
    self.replace( to_sym() )
  end
  
#  def to_s
#    "{#{each{|k,v| k.to_s + ':' + v.to_s + ' '}}}"
#  end
end



class String
  def pluralize
    case self
    when /us$/
      return self.sub(/us$/, 'i' )
    when /s$/
      return self
    when /man$/
      return self.sub(/an$/, 'men' )
    else
    return "#{self}s"
    end
  end
end


class Array
  def to_s
    "[#{join(",")}]"
  end
end


$config = {} if not defined? $config
if Module.constants.index "CONFIG_FILE" and FileTest.exist?(CONFIG_FILE)
  File.open( CONFIG_FILE ) { |f| $config = YAML::load( f ).to_sym }
end
dputs 1, "config is #{$config.inspect}"
$name = $0.match( /.*\/(.*).rb/ )[1]

require 'RPCQooxdoo'
require 'Value'
require 'Entity'
require 'View'
require 'Permission'
require 'Session'
require 'LogActions'
require 'Welcome'
require 'getoptlong'

module QooxView
  def self.do_opts( dir_entities, dir_views )
    opts = GetoptLong.new(
    [ "--help", "-h", GetoptLong::NO_ARGUMENT ],
    [ "--i18n", "-t", GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--po", "-p", GetoptLong::NO_ARGUMENT ]
    )
    opts.each{|o,a|
      case o
      when "--help"
        puts "Usage: #{$0} [-t] [--help]"
        puts "\t-t [lang]\tUpdate translations - takes an optional language-argument"
        puts "\t-p\tCreate .mo-files"
        puts "\t--help\tShow this help"
        exit
      when "--i18n"
        %x[ mkdir -p po; rm -f po/#{$name}.pot ]
        cmd = "rgettext -r #{File.dirname(__FILE__) + '/QooxParser.rb'} -o po/#{$name}.pot" +
        " #{dir_entities}/*.rb #{dir_views}/*.rb #{dir_views}/*/*.rb"
        %x[ #{cmd} ]
        if a.length > 0
          pofile = "po/#{$name}-#{a}.po"
          potfile = "po/#{$name}.pot"
          if File.exists? pofile
            %x[ mv #{pofile} #{pofile}.tmp ]
            %x[ msgmerge #{pofile}.tmp #{potfile} -o #{pofile} ]
          else
            %x[ cp #{potfile} #{pofile} ]
          end
        end
        exit
      when "--po"
        dputs 2, "Making mo-files"
        Dir.glob( "po/#{$name}-*.po").each{|po|
          lang = po.match(/.*#{$name}-(.*).po/)[1]
          dputs 2, "Doint po-file #{po} for language #{lang}"
          path = "po/#{lang}/LC_MESSAGES"
          %x[ mkdir -p #{path}]
          %x[ rmsgfmt #{po} -o #{path}/#{$name}.mo]
        }
      end
    }
  end

  def self.init( dir_entities = nil, dir_views = nil )
    if not ( Module.constants.index( 'Test' ) )
      dputs 0, "Doing options"
      self.do_opts( dir_entities, dir_views )
    end

    GetText.bindtextdomain( $name, :path => "po" )
    GetText.locale = "fr"

    # Include all modules in the dir_entities and dir_views
    # directories
    dputs 0, "Starting init with entities:views = #{[dir_entities, dir_views].join(':')}"
    [ dir_entities, dir_views ].each{|d|
      if d
        Dir[d+"/**/*.rb"].each{|f| require(f)}
      end
    }

    if not Permission.list.index( "default" )
      Permission.add( 'default', '.*' )
    end

    dputs 0, "Starting RPCQooxdooServices"
    # Get an instance of all Qooxdoo-services
    rpcqooxdoo = RPCQooxdooService.new
  end

  # The main function, used to start it all
  def self.startWeb( port = 3302 )
    # Suppose we've not being initialized when there are no permissions
    if Permission.list.size == 0
    self.init
    end

    if webrick = $config[:webrick]
      if webrick[:port]
        port = webrick[:port]
        dputs 0, "Configuring port for #{port}"
      end
    end

    # And start the webrick-server
    # First check whether QooxDoo is running in source- or buid-mode
    dir_html = File.exist?( File.dirname( __FILE__ ) + "/Frontend/build/script/frontend.js" ) ?
      "build" : "source"
    dputs 3, "Directory for Frontend is: #{dir_html}"
    log_msg( "main", "Starting up" )
    RPCQooxdooHandler.webrick( port, File.dirname( __FILE__ ) + "/Frontend/#{dir_html}/" )
  end
end
