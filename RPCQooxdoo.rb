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
  @@is_instance = false
  
  # As we can't call .new during "inherited", we have
  # to do it afterwards - too bad.
  def initialize
    # The entities have to be initialized before the views
    [ "Entities", "View" ].each{|e|
      @@services_hash.each_pair{|k,v|
        if k =~ /^#{e}/
          dputs 3, "RPC: making an instance of #{k} with #{v}"
          @@services_hash[k] = v.new
        end
      }
    }
    @@is_instance = true
  end
  
  # Catches the name of the new class
  def self.inherited( subclass )
    #    name = "#{subclass}".sub( /^.*?_/, "" ).gsub( '_', '.' )
    name = "#{subclass}".gsub( '_', '.' )
    super_name = subclass.superclass.name
    if super_name != "RPCQooxdooService"
      name = "#{super_name}.#{name}"
    end
    dputs 5, "A new handler -#{subclass} is created for the class: #{super_name} with path #{name}"
    @@services_hash[ name ] = subclass
  end
  
  def self.services
    @@services_hash
  end
  
  # Adds a new service of type "subclass" and stores it under "name"
  def self.add_new_service( subclass, name )
    dputs 5, "Add a new service: #{subclass} as #{name}"
    @@services_hash[ name ] = @@is_instance ? subclass.new : subclass
  end
end

class RPCQooxdooHandler
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
  def self.request( id, service, method, params )
    session = Session.find_by_id( params[0].shift )
    dputs 3, "session is #{session}"
    
    if service =~ /^View/ and session
      if not session.can_view( service )
        return self.error( 2, 3, "Not allowed to view that!", id )
      end
    end
    
    dputs 3, "Going to call #{service}, #{method}"
    # Get an answer with some error-checking

    if RPCQooxdooService::services.has_key?( service )
      s = RPCQooxdooService::services[ service ]
      method = "rpc_#{method}"
      if s.respond_to?( method )
        dputs 3, "Calling #{method} with #{params.inspect}"
        begin
          parsed = s.parse_request( method, session, params[0] )
          return self.answer( s.parse_reply( method, session, parsed ), id )
        rescue Exception => e  
          dputs 0, "Error while handling #{method} with #{params.inspect}: #{e.message}"
          dputs 0, "#{e.inspect}"
          dputs 0, "#{e.to_s}"
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
  def self.parse( stid, d )
    answer = nil
    
    # Prepare all variables
    if not d
      answer = self.error( 2,0, "Didn't receive request", -1 )
    else
      data = JSON.parse( d )
      dputs 2, "Request-data is: #{data.inspect}"
      answer = self.request( data['id'], data['service'], data['method'], data['params'] )
    end
    
    # And put it in a nice qx-compatible reply
    dputs 3, "Answer is #{answer}"
    return "qx.io.remote.transport.Script._requestFinished('#{stid}', " +
    "#{ActiveSupport::JSON.encode(answer) } );"
  end
  
  # A more easy handler for a query-hash, e.g. camping or webrick
  def self.parse_query( q )
    self.parse( q['_ScriptTransport_id'], q['_ScriptTransport_data'] )
  end
  
  def self.parse_info( p, q )
    dputs 0, "Path is: #{p.inspect} - Query is: #{q.inspect}"
  end
  
  def self.parse_acaccess( r, p, q )
    dputs 0, "Path is: #{p.inspect} - Query is: #{q.inspect}"
  end
  
  # And a no-worry with Webrick
  def self.webrick( port, dir = "." )
    access_log_stream = File.open('webrick.access.log', 'w')
    server = HTTPServer.new(:Port => port, :Logger => WEBrick::Log.new( "webrick.log" ),
      :AccessLog => [ [ access_log_stream, AccessLog::COMBINED_LOG_FORMAT ] ] )
    # server = HTTPServer.new(:Port => port )
    ['INT', 'TERM'].each { |signal|
      trap(signal){ server.shutdown }
    }
    
    server.mount_proc('/rpc') {|req, res|
      $webrick_request = req
      dputs 5, "Request is #{req.path}"
      res.body = self.parse_query( req.query )
      res['content-type'] = "text/html"
      res['content-length'] = res.body.length
      dputs 2, "RPC-Reply is #{res.body}"
      raise HTTPStatus::OK
    }
    server.mount_proc('/info') {|req, res|
      $webrick_request = req
      dputs 4, "Info-Request is #{req.path}"
      begin
        res.body = self.parse_info( req.path, req.query )
      rescue Exception => e  
        dputs 0, "Error while handling #{method} with #{params.inspect}: #{e.message}"
        dputs 0, "#{e.inspect}"
        dputs 0, "#{e.to_s}"
        puts e.backtrace
        res.body = "Error in handling method"
      end
      res['content-type'] = "text/html"
      res['content-length'] = res.body.length
      dputs 2, "Info-Reply is #{res.body}"
      raise HTTPStatus::OK
    }
    server.mount_proc('/acaccess') {|req, res|
      $webrick_request = req
			ddputs 5, "Webrick_request is #{$webrick_request.inspect}"
      ddputs 4, "ACaccess-Request is #{req.path} and " + 
				"method is #{req.request_method}"
      begin
        res.body = self.parse_acaccess( req.request_method, req.path, req.query )
      rescue Exception => e  
        dputs 0, "Error while handling #{method} with #{params.inspect}: #{e.message}"
        dputs 0, "#{e.inspect}"
        dputs 0, "#{e.to_s}"
        puts e.backtrace
        res.body = "Error in handling method"
      end
      res['content-type'] = "text/html"
      res['content-length'] = res.body.length
      dputs 2, "ACaccess-Reply is #{res.body}"
      raise HTTPStatus::OK
    }
    server.mount( '/tmp', HTTPServlet::FileHandler, "/tmp" )
    server.mount( '/', HTTPServlet::FileHandler, dir )
    
    server.start
  end
  
end
