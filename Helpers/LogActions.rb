#
# Simple class to allow logging of events to a log-file for
# later usage. Also to be used for undo.
#
# It builds upon Entities, from which it is also mainly called - probably a bad
# idea, and the whole "data"-scheme should be outsourced in DataElement.

class LogActions < Entities
  def setup_data
    add_new_storage :CSV, :add_only => true
    @undo = false
    #@logging = false

    value_date :date_stamp
    value_str :data_class
    value_str :data_class_id
    value_str :data_field
    value_str :data_value
    value_str :data
    value_str :msg
    value_str :undo_function
    value_str :data_old

    return true
  end

  # Log one action, with data, which is supposed to be a
  # Hash. Two possibilities:
  # [undo_function] - points to a function which can undo the operation. It will get "data" and "data_old", if applicable
  # [data_old] - eventual old data interesting to "undo_function"
  # It will return the index of the action
  def log_action( data_class, data_id, data, msg = nil, undo_function = nil, data_old = nil )
    ddputs( 3 ){ "Creating log-entry: #{[data, undo_function, data_old].inspect}" }
    create( { :data_field => data.keys[0], :data_value => data[data.keys[0]], 
        :data_class => data_class.to_s, :data_class_id => data_id, 
        :msg => msg,
        :undo_function => undo_function, :data_old => data_old,
        :date_stamp => Time.now.strftime("%Y:%m:%d %H:%M:%S")} )
  end

  # Returns a list of action_ids that match "filter". The
  # default filter just returns everything
  def log_list( filter = { :logactions_id => ".*" } )
    dputs( 3 ){ "Searching for #{filter.inspect}" }
    res = filter_by( filter )
    res.sort!{|a,b| a[:logaction_id].to_i <=> b[:logaction_id].to_i}
    dputs( 3 ){ "And found #{res}" }
    dputs( 5 ){ "Inspected result: #{res.inspect}" }
    return res
  end

  # Undoes a given action
  def log_undo( target, action_id )
    dputs( 3 ){ "Trying to undo #{action_id} with #{target.class}" }
    e = find_by( :logactions_id, action_id )
    if e[:undo_function]
      dputs( 3 ){ "Going to call undo-function " +
          "#{[e[:undo_function], e[:data], e[:data_old]].inspect}" }
      target.send( e[:undo_function], e[:data], e[:data_old] )
    end
  end
end

class LogAction < Entity
end
