=begin rdoc
RPCQooxdoo - simple JSON-handler for Qooxdoo-RPC cross-domain requests ONLY!

RPCQooxdooService - to be inherited by your services
RPCQooxdooHandler - handles requests from Qooxdoo in different ways

Each Qooxdoo-request has a service, method and a params. This class allows
a convenient way to map these to Ruby classes and do as less as possible.

In order to add a service, you just have to inherit from RPCQooxdooSerivce, and
your new service will automatically be available under the following name:
* DELETED, REMOVE THE COMMENT IF NEEDED:
    the first part till the first "_" is cut - allowing for else overlapping
    service names
* all "_" in the name are replaced with "."
RPCQooxdooService makes an instance of your class, which will be used thereafter
to handle calls to different methods

The method of the RPC call are simply mapped to methods of the class.
The return of the method is wrapped up to fit JSON

In your HTTP-handler you have to either call
* RPCQooxdooHandler::parse( stid, data ) - if you have the data:
  * stid is the _ScriptTransport_id - field
  * data is the _ScriptTransport_data - field
* RPCQooxdooHandler::parse_query( q ) - if you're using something that gives the
  query as a hash, Camping or Webrick

Or you leave it all to Webrick by calling
  RPCQooxdooHandler::webrick( port )
=end

require 'webrick'

include WEBrick

class RPCQooxdooService
  @@services_hash = {}
  @@needs = {}
  @@is_instance = false
  
  # As we can't call .new during "inherited", we have
  # to do it afterwards - too bad.
  def initialize
    do_init = true

    while do_init
      do_init = false
      
      # The entities have to be initialized before the views
      [ "Entities", "View" ].each{|e|
        @@services_hash.sort.each{|k,v|
          if k =~ /^#{e}/
            if @@services_hash[k].class == Class
              dputs(5){"#{@@needs.inspect}"}
              if @@needs.has_key?(k) and 
                  @@services_hash[@@needs[k]].class == Class
                dputs(3){"Not initializing #{k}, as it needs #{@@needs[k]}"}
                do_init = true
              else
                dputs( 3 ){ "RPC: making an instance of #{k.inspect} with #{v.inspect}" }
                @@services_hash[k] = v.new
              end
            end
          end
        }
      }
    end
    
    RPCQooxdooService.migrate_all

    @@is_instance = true
  end
  
  def self.migrate_all
    # And now do eventual migrations on everybody
    @@services_hash.each_pair{|k,v|
      if k =~ /^Entities/
        dputs( 4 ){ "Migration of #{k}" }
        v.migrate
      end
    }
  end
  
  def self.entities
    RPCQooxdooService.services.each{|service_name,service_class|
      if service_name.to_s =~ /^Entities/
        dputs(4){"Found Entities of #{service_name.inspect}"}
        yield service_class
      end
    }    
  end
  
  # Catches the name of the new class
  def self.inherited( subclass )
    #    name = "#{subclass}".sub( /^.*?_/, "" ).gsub( '_', '.' )
    name = "#{subclass}".gsub( '_', '.' )
    super_name = subclass.superclass.name
    if super_name != "RPCQooxdooService"
      name = "#{super_name}.#{name}"
    end
    dputs( 5 ){ "A new handler -#{subclass} is created for the class: #{super_name} with path #{name}" }
    @@services_hash[ name ] = subclass
  end
  
  def self.services
    @@services_hash
  end
  
  def self.migrate( name )
    @@services_hash[ name ].migrate    
  end
  
  # Adds a new service of type "subclass" and stores it under "name"
  def self.add_new_service( subclass, name )
    dputs( 5 ){ "Add a new service: #{subclass} as #{name}" }
    @@services_hash[ name ] = subclass.new
    self.migrate( name )
  end
end

class RPCQooxdooHandler
  @@paths = {}

  # self.answer and self.error return a hash, which will be converted later
  def self.answer( result, id, error = nil )
    not result and result = []
    { "result" => result, "error" => error, "id" => id }
  end

  def self.error( origin, code, message, id )
    self.answer( nil, id,
      { "origin" => origin, "code" => code, "message" => message }.to_json )
  end

  # Replies to a request
  def self.request( id, service, method, params, web_req = nil )
    session = Sessions.match_by_sid( params[0].shift ) || Sessions.create
    dputs( 3 ){ "session is #{session.inspect}" }

    if service =~ /^View/ and session
      dputs( 3 ){ "Going to test if we can view #{service}" }
      if not session.can_view( service )
        return self.error( 2, 3, "Not allowed to view that!", id )
      end
      session.web_req = web_req
    end
    
    dputs( 3 ){ "Going to call #{service}, #{method}" }
    # Get an answer with some error-checking

    if RPCQooxdooService::services.has_key?( service )
      s = RPCQooxdooService::services[ service ]
      method = "rpc_#{method}"
      if s.respond_to?( method )
        dputs( 3 ){ "Calling #{method} with #{params.inspect}" }
        begin
          parsed = s.parse_request( method, session, params[0] )
          dputs( 4 ){"Parsed request is #{parsed.inspect}"}
          answer = s.parse_reply( method, session, parsed )
          dputs( 3 ){ "First answer is #{answer.inspect}" }

          if answer.class == Array
            answer.delete_if{|a|
              a.class != Hash or
                ( a.keys.join != "cmddata" and
                  a.keys.join != "datacmd" )
            }
          else
            dputs( 2 ){ "Creating empty reply" }
            answer = [{:cmd => "none", :data => []}]
          end

          dputs( 3 ){ "Final answer is #{answer.inspect}" }
          return self.answer( answer, id )
        rescue Exception => e  
          dputs( 0 ){ "Error while handling #{method} with #{params.inspect}: #{e.message}" }
          dputs( 0 ){ "#{e.inspect}" }
          dputs( 0 ){ "#{e.to_s}" }
          puts e.backtrace
          return self.error( 2, 2, "Error in handling method", id )
        end
      else
        return self.error( 2, 2, "No such method", id )
      end
    else
      return self.error( 2, 1, "No such service", id )
    end
  end
  
  # Parsing of an incoming RPC-request - returns a string to be sent
  # to the client
  def self.parse( stid, d, web_req = nil )
    answer = nil
    
    # Prepare all variables
    if not d
      answer = self.error( 2,0, "Didn't receive request", -1 )
    else
      data = JSON.parse( d )
      dputs( 3 ){ "Request-data is: #{data.inspect}" }
      answer = self.request( data['id'], data['service'], data['method'], data['params'], web_req )
    end
    
    # And put it in a nice qx-compatible reply
    dputs( 3 ){ "Answer is #{answer}" }
    return "qx.io.remote.transport.Script._requestFinished('#{stid}', " +
      "#{ActiveSupport::JSON.encode(answer) } );"
  end
  
  # A more easy handler for a query-hash, e.g. camping or webrick
  def self.parse_query( q )
    self.parse( q.query['_ScriptTransport_id'], q.query['_ScriptTransport_data'], q )
  end
  
  # And a no-worry with Webrick
  def self.webrick( port, dir = "." )
    access_log_stream = File.open('webrick.access.log', 'w')
    logger = [[ access_log_stream, AccessLog::COMBINED_LOG_FORMAT ]]
    #logger.push [$stderr, WEBrick::AccessLog::COMMON_LOG_FORMAT]
    #logger.push [$stderr, WEBrick::AccessLog::REFERER_LOG_FORMAT]
    server = HTTPServer.new(:Port => port, :Logger => WEBrick::Log.new( "webrick.log" ),
      :AccessLog => logger )
    # server = HTTPServer.new(:Port => port )
    ['INT', 'TERM'].each { |signal|
      trap(signal){ server.shutdown }
    }
    
    # This is the remote-procedure-handling from the Frontend
    server.mount_proc('/rpc') {|req, res|
      $webrick_request = req
      dputs( 5 ){ "Request is #{req.inspect}" }
      dputs( 4 ){ "Request-path is #{req.path}" }
      res.body = self.parse_query( req )
      res['content-type'] = "text/html"
      res['content-length'] = res.body.length
      dputs( 3 ){ "RPC-Reply is #{res.body}" }
      raise HTTPStatus::OK
    }
		
    # And any other handling required by modules
    @@paths.each{|path,cl|
      dputs( 1 ){ "Mounting path /#{path} to class #{cl.name}" }
      server.mount_proc("/#{path.to_s}") {|req, res|
        $webrick_request = req
        dputs( 5 ){ "Webrick_request is #{$webrick_request.inspect}" }
        dputs( 4 ){ "#{path}-Request is #{req.path} and " +
            "method is #{req.request_method}" }
        
        status = HTTPStatus::OK
        res['content-type'] = "text/html"
        begin
          if cl.respond_to? :parse_req_res
            res.body = cl.parse_req_res( req, res ).to_s
          elsif cl.respond_to? :parse_req
            res.body = cl.parse_req( req ).to_s
          else
            res.body = cl.parse( req.request_method, req.path, req.query ).to_s
          end
        rescue Exception => e  
          dputs( 0 ){ "Error while handling #{cl.name} with #{req.inspect}: #{e.message}" }
          dputs( 0 ){ "#{e.inspect}" }
          dputs( 0 ){ "#{e.to_s}" }
          puts e.backtrace
          res.body = "Error in handling method"
        end
        res.body.force_encoding( "ASCII-8BIT" )
        res['content-length'] = res.body.length
        res['status'] = status
        if res['content-type'] == "text/html"
          dputs( 3 ){ "#{path}-reply is #{res.body.inspect}" }
        end
        dputs( 3 ){"Status is #{status.inspect}"}
      }
    }

    server.mount( '/tmp', HTTPServlet::FileHandler, "/tmp" )
    server.mount( '/', HTTPServlet::FileHandler, dir )
    
    server.start
    exit
  end

  def self.add_path( path, cl )
    @@paths[path.to_sym] = cl
  end
  
end

class RPCQooxdooPath
  def self.inherited( subclass )
    name = subclass.name.downcase
    dputs( 0 ){ "A new path -#{subclass} is created for the class: #{subclass} with path /#{name}" }
    RPCQooxdooHandler.add_path( name, subclass )
  end
end
