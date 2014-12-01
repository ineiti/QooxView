# This will be the only InterCenterCommunication-point to "Gestion"
# TODO
# - secure connection
# Implemented:
# - simple get-function
# - longer post-function
# - put json around everything
require 'cgi'
require 'net/http'

class ICC < RPCQooxdooPath
  @@transfers = {}

  def self.response(code, msg, json: true)
    if json
      {code: code, msg: msg}.to_json
    else
      {code: code, msg: msg}
    end
  end

  def self.parse_req(req)
    #dputs(4) { "Request: #{req.inspect}" }
    #dputs_func
    if req.request_method == 'POST'
      path, query, addr = req.path, req.query.to_sym, RPCQooxdooHandler.get_ip(req)
      dputs(4) { "Got query: #{path} - #{query.inspect} - #{addr}" }

      if query._cmdkey == 'start'
        log_msg :ICC, "Got start-query: #{path} - #{query.inspect} - #{addr}"
        d = JSON.parse(query._data).to_sym
        dputs(3) { "d is #{d.inspect}" }
        if (user = Persons.match_by_login_name(d._user)) and
            (user.check_pass(d._pass))
          @@transfers[d._tid] = d.merge(:data => [])
          d._chunks > 0 and return self.response('OK', 'send data')
          query._cmdkey = d._tid
          query._data = []
        else
          dputs(3) { "User #{d._user.inspect} with pass #{d._pass.inspect} unknown" }
          return self.response('Error', 'authentication')
        end
      end
      if tr = @@transfers[query._cmdkey]
        counter = query._counter.to_i
        dputs(2) { "Found transfer-id #{query._cmdkey}/"+
            "#{counter+1}/#{tr._chunks} - #{tr._method}" }
        if tr._data[counter]
          dputs(1) { "Received block #{counter} double - discarding" }
        else
          tr._data[counter] = query._data
          if counter == tr._chunks - 1
            tr._data = tr._data.join
            if Digest::MD5.hexdigest(tr._data) == tr._md5
              dputs(1) { "Successfully received cmdkey #{query._cmdkey}" }
              ret = self.response('OK', self.data_received(tr))
            else
              dputs(1) { "cmdkey #{tr._cmdkey} transmitted with errors, " +
                  "#{Digest::MD5.hexdigest(tr._data)} instead of #{tr._md5}" }
              ret = self.response('Error', 'wrong MD5')
            end
            @@transfers.delete query._cmdkey
            return ret
          else
            return self.response('OK', "send #{tr._chunks - counter - 1} more chunks")
          end
        end
      end
      return self.response('Error', 'must start or use existing cmdkey')
    else # GET-request
      path = /.*\/([^\/]*)\/([^\/]*)$/.match(req.path)
      dputs(3) { "Path #{req.path} is #{path.inspect}" }
      query = CGI.parse(req.query_string)
      log_msg :ICC, "Got query: #{path.inspect} - #{query}"
      self.request(path[1], path[2], query)
    end
  end

  def self.request(entity_name, m, query_json)
    m =~ /^icc_/ and log_msg :ICC, "Method #{m} includes 'icc_' - probably not what you want"
    method = "icc_#{m}"
    if en = Object.const_get(entity_name)
      dputs(3) { "Sending #{method} to #{entity_name}" }
      query={}
      query_json.each_pair { |k, v| query[k] = JSON.parse(v.first) }
      dputs(3) { "Found query #{query.inspect}" }
      self.response('OK', en.send(method, query))
    else
      self.response('Error', log_msg(:ICC, "Object #{entity_name} doesn't exist"))
    end
  end

  def self.data_received(tr)
    if tr._method.sub!(/^json@/, '')
      tr._data = JSON.parse(tr._data).first
    end
    entity_name, m = tr._method.split('.')
    method = "icc_#{m}"
    Object.const_get(entity_name)
    if en = Object.const_get(entity_name) # and en.respond_to? method
      dputs(3) { "Sending #{method} to #{entity_name}" }
      en.send(method, tr)
    else
      log_msg :ICC, "Error: Object #{entity_name} has no method #{method}"
    end
  end

  def self.send_post(url, cmdkey, data, counter: 0, retries: 4)
    path = URI.parse(url)
    post = {:cmdkey => cmdkey, :data => data, :counter => counter}
    dputs(3) { "Sending to #{path.inspect}: #{cmdkey}/#{count}" }
    err = self.response('Error', 'Unknown', json: false)
    (1..retries).each { |i|
      begin
        ret = Net::HTTP.post_form(path, post)
        dputs(2) { "Return-value is #{ret.inspect}, #{ret.message}, #{ret.code}, body is #{ret.body}" }
        if ret.code.to_i == 200
          begin
            return JSON.parse(ret.body)
          rescue JSON::ParserError
            dputs(1) { "Couldn't parse #{ret.body}" }
            err._msg = 'Reply parse-error'
            sleep 5
          end
        else
          dputs(1) { "Error-reply was #{ret.inspect}" }
          err._msg = "Error: #{ret.code}:#{ret.message}"
          sleep 5
        end
      rescue Timeout::Error
        dputs(1) { 'Timeout occured' }
        err._msg = 'Timeout occured'
      rescue Errno::ECONNRESET
        dputs(1) { 'Connection reset' }
        err._msg = 'Connection reset'
      end
    }
    return err
  end

  def self.transfer(login, method, transfer = '', url: ConfigBase.server_uri, json: true,
      &percent)
    block_size = ConfigBase.block_size.to_i
    if block_size < 128
      dputs(0) { "Unacceptable block-size of #{block_size}" }
      return self.response('Error', 'No block-size', json: false)
    end
    if json
      method.prepend 'json@'
      transfer = [transfer].to_json
    end

    transfer_md5 = Digest::MD5.hexdigest(transfer)
    t_array = []
    while t_array.length * block_size < transfer.length
      start = (block_size * t_array.length)
      t_array.push transfer[start..(start+block_size -1)]
    end
    dputs(2) { "Transfer-size is #{transfer.size} and cut up in "+
        "#{t_array.size} pieces of #{block_size} length" }

    dputs(3) { "Going to transfer: #{t_array.inspect}" }
    percent and percent.call('0%')
    tid = Digest::MD5.hexdigest(rand.to_s)
    ret = ICC.send_post(url, :start,
                        {:method => method, :chunks => t_array.length,
                         :md5 => transfer_md5, :tid => tid,
                         :user => login.login_name, :pass => login.password_plain}.to_json)
    return ret if ret._code == 'Error'
    t_array.each_index { |i|
      if percent
        p = "#{((i+1) * 100 / t_array.length).floor}%"
        percent.call p
        dputs(3) { "Percentage done: #{p}" }
      end
      dputs(2) { "Sending id #{tid}/#{i+1}" }
      ret = ICC.send_post(url, tid, t_array[i], counter: i)
      return ret if ret =~ /^Error:/
    }
    return ret
  end

  def self.get(entity_name, method, args: {}, url: ConfigBase.server_uri)
    args_json = {}
    args.each_pair { |k, v| args_json[k] = v.to_json }
    path = URI.parse("#{url}/#{entity_name}/#{method}?#{URI.encode_www_form(args_json)}")
    JSON::parse(Net::HTTP.get(path))
  end

end
