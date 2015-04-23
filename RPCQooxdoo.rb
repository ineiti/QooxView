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
  def initialize(services = '.*')
    get_services(services)
  end

  def get_services(services = '.*')
    #dputs_func
    do_init = true

    while do_init
      do_init = false
      dputs(3) { "List is: #{@@services_hash.keys.inspect} for services #{services.inspect}" }

      # The entities have to be initialized before the views
      %w(Entities View).each { |e|
        @@services_hash.sort.each { |k, v|
          if k =~ /^#{e}/ and k =~ /#{services}/
            dputs(3) { "Initializing #{k.inspect} with #{v.inspect}" }
            if @@services_hash[k].class == Class
              dputs(5) { "Needs is: #{@@needs.inspect}" }
              if @@needs.has_key?(k) and
                  @@services_hash[@@needs[k]].class == Class
                dputs(3) { "Not initializing #{k}, as it needs #{@@needs[k]}" }
                get_services(@@needs[k])
                do_init = true
              else
                dputs(3) { "RPC: making an instance of #{k.inspect} with #{v.inspect}" }
                @@services_hash[k] = v.new
              end
            end
          end
        }
      }
    end

    @@is_instance = true
  end

  def self.migrate_all
    # And now do eventual migrations on everybody
    @@services_hash.each_pair { |k, v|
      if k =~ /^Entities/ and v.class != Class
        dputs(3) { "Migration of #{k}" }
        oldload = v.loading
        v.loading = true
        v.migrate
        v.loading = oldload
        dputs(3) { "Migration of #{k}" }
      end
    }
  end

  def self.entities
    RPCQooxdooService.services.each { |service_name, service_class|
      if service_name.to_s =~ /^Entities/
        dputs(4) { "Found Entities of #{service_name.inspect}" }
        yield service_class
      end
    }
  end

  # Catches the name of the new class
  def self.inherited(subclass)
    #    name = "#{subclass}".sub( /^.*?_/, "" ).gsub( '_', '.' )
    name = "#{subclass}".gsub('_', '.')
    super_name = subclass.superclass.name
    if super_name != 'RPCQooxdooService'
      name = "#{super_name}.#{name}"
    end
    dputs(5) { "A new handler -#{subclass} is created for the class: #{super_name} with path #{name}" }
    @@services_hash[name] = subclass
  end

  def self.services
    @@services_hash
  end

  # Adds a new service of type "subclass" and stores it under "name"
  def self.add_new_service(subclass, name)
    dputs(5) { "Add a new service: #{subclass} as #{name}" }
    @@services_hash[name] = subclass.new
  end
end

class RPCQooxdooHandler
  @@paths = {}
  @@file_paths = {}

  # self.answer and self.error return a hash, which will be converted later
  def self.answer(result, id, error = nil)
    not result and result = []
    {'result' => result, 'error' => error, 'id' => id}
  end

  def self.error(origin, code, message, id)
    self.answer(nil, id,
                {'origin' => origin, 'code' => code, 'message' => message}.to_json)
  end

  def self.get_ip(req)
    dputs(3) { "header is #{req.header.inspect} - peeraddr is #{req.peeraddr.inspect}" }
    if (ret = req.header['x-forwarded-for']) && (ret != [])
      dputs(3) { "x-forward of #{ret.inspect}" }
      ret.first
    else
      dputs(3) { "peeraddr - #{req.peeraddr[3]}" }
      req.peeraddr[3]
    end
  end

  # Replies to a request
  def self.request(id, service, method, params, web_req = nil)
    #dp params[0]
    #dp Sessions.search_all_
    #dp web_req
    show_request_reply = 3
    time = Timing.new(3)
    session = Sessions.match_by_sid(params[0].shift) || Sessions.create
    dputs(3) { "session is #{session.inspect}" }

    if service =~ /^View/ and session
      dputs(3) { "Going to test if we can view #{service}" }
      if not session.can_view(service)
        return self.error(2, 3, 'Not allowed to view that!', id)
      end
      session.web_req = web_req
      if web_req
        session.client_ip = self.get_ip(web_req)
      end
    end

    dputs(show_request_reply) { "Going to call #{service}, #{method}. Args = #{params.inspect}" }
    # Get an answer with some error-checking

    if RPCQooxdooService::services.has_key?(service)
      s = RPCQooxdooService::services[service]
      method = "rpc_#{method}"
      if s.respond_to?(method)
        dputs(3) { "Calling #{method} with #{params.inspect}" }
        begin
          parsed = s.parse_request(method, session, params[0])
          time.probe("Parsing #{service}.#{method}")
          dputs(4) { "Parsed request is #{parsed.inspect}" }
          answer = s.parse_reply(method, session, parsed)
          time.probe("Replying #{service}.#{method}")
          dputs(3) { "First answer is #{answer.inspect}" }

          if answer.class == Array
            answer.delete_if { |a|
              a.class != Hash or
                  (a.keys.join != 'cmddata' and
                      a.keys.join != 'datacmd')
            }
          else
            dputs(3) { 'Creating empty reply' }
            answer = [{:cmd => 'none', :data => []}]
          end

          dputs(show_request_reply) { "Final answer is #{answer.inspect}" }
          return self.answer(answer, id)
        rescue Exception => e
          dputs(0) { "Error while handling #{method} with #{params.inspect}: #{e.message}" }
          dputs(0) { "#{e.inspect}" }
          dputs(0) { "#{e.to_s}" }
          puts e.backtrace
          return self.error(2, 2, 'Error in handling method', id)
        end
      else
        return self.error(2, 2, "No such method #{method} for #{s.class.name}", id)
      end
    else
      return self.error(2, 1, 'No such service', id)
    end
  end

  # Parsing of an incoming RPC-request - returns a string to be sent
  # to the client
  def self.parse(data, web_req = nil)
    answer = nil

    # Prepare all variables
    if not data
      answer = self.error(2, 0, "Didn't receive request", -1)
    else
      dputs(3) { "Request-data is: #{data.inspect}" }
      answer = self.request(data['id'], data['service'], data['method'], data['params'], web_req)
    end

    # And put it in a nice qx-compatible reply
    dputs(3) { "Answer is #{answer}" }
    return answer
  end

  # A more easy handler for a query-hash, e.g. camping or webrick
  def self.parse_query(q)
    request = JSON.parse(q.body)
    dputs(4) { "JSON of body is #{request.inspect}" }
    self.parse(request, q).to_json
  end

  def self.parse_query_xdomain(q)
    stid = q.query['_ScriptTransport_id']
    answer = self.parse(JSON.parse(q.query['_ScriptTransport_data']), q)

    return "qx.io.remote.transport.Script._requestFinished('#{stid}', " +
        "#{answer.to_json} );"
  end

  @@server = []

  # And a no-worry with Webrick
  def self.webrick(port, dir = ".", duration = nil)
    dputs(3) { "Starting webrick for port #{port}, dir #{dir}, duration #{duration.inspect}" }
    access_log_stream = File.open('webrick.access.log', 'w')
    logger = [[access_log_stream, AccessLog::COMBINED_LOG_FORMAT]]
    #logger.push [$stderr, WEBrick::AccessLog::COMMON_LOG_FORMAT]
    #logger.push [$stderr, WEBrick::AccessLog::REFERER_LOG_FORMAT]
    if @@server[port]
      dputs(2) { 'Server already running - halting' }
      @@server[port].shutdown
    end
    begin
      @@server[port] = HTTPServer.new(:Port => port, :Logger => WEBrick::Log.new('webrick.log'),
                                      :AccessLog => logger, :DoNotReverseLookup => true)
    rescue Errno::EADDRINUSE => e
      dputs(0) { "Couldn't bind to address #{port} - already in use" }
      raise Errno::EADDRINUSE
    end
    # server = HTTPServer.new(:Port => port )

    #server.mount "/rpc", GetPost
    # This is the remote-procedure-handling from the Frontend
    @@server[port].mount_proc('/rpc') { |req, res|
      $webrick_request = req
      dputs(5) { "Request is #{req.inspect}" }
      dputs(5) { "Body is is #{req.body.inspect}" }
      dputs(4) { "Request-path is #{req.path}" }
      if req.body
        res.body = self.parse_query(req)
      else
        res.body = self.parse_query_xdomain(req)
      end
      #res['content-type'] = "text/html"
      res['content-type'] = 'application/json'
      res['content-length'] = res.body.length
      dputs(3) { "RPC-Reply is #{res.body}" }
      raise HTTPStatus::OK
    }

    # And any other handling required by modules
    @@paths.each { |path, cl|
      dputs(2) { "Mounting path /#{path} to class #{cl.name}" }
      @@server[port].mount_proc("/#{path.to_s}") { |req, res|
        $webrick_request = req
        dputs(5) { "Webrick_request is #{$webrick_request.inspect}" }
        dputs(4) { "#{path}-Request is #{req.path} and " +
            "method is #{req.request_method}" }

        status = HTTPStatus::OK
        res['content-type'] = 'text/html'
        begin
          if cl.respond_to? :parse_req_res
            res.body = cl.parse_req_res(req, res).to_s
          elsif cl.respond_to? :parse_req
            res.body = cl.parse_req(req).to_s
          else
            res.body = cl.parse(req.request_method, req.path, req.query).to_s
          end
        rescue Exception => e
          dputs(0) { "Error while handling #{cl.name} with #{req.inspect}: #{e.message}" }
          dputs(0) { "#{e.inspect}" }
          dputs(0) { "#{e.to_s}" }
          puts e.backtrace
          res.body = 'Error in handling method'
        end
        res.body.force_encoding(Encoding::ASCII_8BIT)
        res['content-length'] = res.body.length
        res['status'] = status
        if res['content-type'] == 'text/html'
          dputs(3) { "#{path}-reply is #{res.body.inspect}" }
        end
        dputs(3) { "Status is #{status.inspect}" }
      }
    }

    @@file_paths.each { |web, dir|
      dputs(2) { "Mounting web-path /#{web} to file-path #{dir}" }
      @@server[port].mount("/#{web}", HTTPServlet::FileHandler, dir)
    }

    @@server[port].mount('/tmp', HTTPServlet::FileHandler, '/tmp')
    @@server[port].mount('/', HTTPServlet::FileHandler, dir)

    if not duration
      dputs(2) { 'Starting forever' }
      %w(INT TERM).each { |signal|
        trap(signal) {
          dputs(3) { 'Shutting down http-server' }
          @@server[port].shutdown
        }
      }
      @@server[port].start
    else
      dputs(2) { "Starting for #{duration} seconds" }
      server_loop = Thread.new {
        @@server[port].start
        dputs(2) { 'Webrick stopped' }
      }
      sleep duration
      @@server[port].shutdown
      server_loop.join
    end
  end

  def self.add_path(path, cl)
    @@paths[path.to_sym] = cl
  end

  def self.add_file_path(web, dir)
    @@file_paths[web.to_sym] = dir
  end

end

class RPCQooxdooPath
  def self.inherited(subclass)
    name = subclass.name.downcase
    dputs(2) { "A new path -#{subclass} is created for the class: #{subclass} with path /#{name}" }
    RPCQooxdooHandler.add_path(name, subclass)
  end

  def self.sanitize(filename)
    filename.gsub(/[^0-9A-z._-]/, '')
  end
end
