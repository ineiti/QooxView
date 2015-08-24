class CSV < StorageType

  def configure(config)
    dputs(3) { "Configuring CSV with #{@name}" }
    @csv_dir = File.join($data_dir, get_config('data', :StorageType, :data_dir))
    @add_only = false
    @backup_count = 5
    super config
    @csv_backup = File.join(@csv_dir, 'backup')
    @csv_name = "#{@entity.class.name}.csv"
    @csv_file = File.join(@csv_dir, @csv_name)
    @csv_backup_file = File.join(@csv_backup, @csv_name)
    dputs(5) { "data_file is #{@csv_file}" }

    @mutex = Mutex.new
  end

  def write_line(f, d)
    # Only write non-nil data
    d = d.select { |k, v| v }
    # And convert the Array back into a Hash
    d = Hash[*d.flatten(1)]
    # If there is only nil-data (except the field-id), don't write it!
    if d.length > 1
      dputs(5) { "Writing line #{d.inspect}" }
      f << d.to_json << "\n"
    end
  end

  # Saves the data stored, optionally takes an index to say
  # which data needs to be saved
  def save(data)
    #dputs_func
    @add_only ?
        dputs(5) { "Not saving data for #{@name}" } :
        @mutex.synchronize {
          begin
            dputs(3) { "Saving data for #{@name} to #{@csv_dir} - #{@csv_file}" }
            [@csv_dir, @csv_backup].each { |d|
              FileUtils.mkdir_p d unless File.exists? d
            }
            dputs(5) { "Data is #{data.inspect}" }

            if File.exists? @csv_file
              time = File.mtime(@csv_file).strftime('%Y%m%d_%H%M%S')
              backup = "#{@csv_backup_file}.#{time}"
              counter = 1
              while File.exists? backup
                backup = "#{@csv_backup_file}.#{time}-#{counter}"
                counter += 1
              end
              FileUtils.cp @csv_file, backup
            end

            tmpfile = "#{@csv_file}_tmp"
            File.open(tmpfile, 'w') { |f|
              data_each(data) { |d|
                write_line(f, d)
                if di = @entity.data_instances[d[@data_field_id]]
                  di.changed = false
                end
              }
            }
            FileUtils.mv tmpfile, @csv_file
            #%x[ sync ]
            dputs(3) { 'Delete oldest file(s)' }
            if (backups = Dir.glob("#{@csv_backup_file}.*").sort).size > @backup_count
              oldfiles = backups.first(backups.size - @backup_count)
              dputs(3) { "Deleting #{oldfiles.inspect}" }
              FileUtils.rm oldfiles
            end
          rescue Exception => e
            dputs(0) { "Error: couldn't save CSV #{@name}" }
            dputs(0) { "#{e.inspect}" }
            dputs(0) { "#{e.to_s}" }
            puts e.backtrace
          end
        }
  end

  # Each new entry is directly stored if @add_only is true
  def data_create(data)
    @add_only or return
    @mutex.synchronize {
      begin
        FileUtils.mkdir_p @csv_dir unless File.exists? @csv_dir
        tmpfile = "#{@csv_file}_tmp"
        File.exists? @csv_file and FileUtils.cp @csv_file, tmpfile
        File.open(tmpfile, 'a') { |f|
          write_line(f, data)
        }
        #%x[ sync ]
        dputs(5) { 'Moving file' }
        FileUtils.mv tmpfile, @csv_file
      rescue Exception => e
        dputs(0) { "Error: couldn't save newly created data #{self.class.name}" }
        dputs(0) { "#{e.inspect}" }
        dputs(0) { "#{e.to_s}" }
        puts e.backtrace
      end
    }
  end

  # Restores somewhat sane directory with all saved files in 'backup'
  def cleanup
    FileUtils.mkdir @csv_backup unless File.exists? @csv_backup
    log_msg :CSV, "Cleaning up #{@csv_file}"
    Dir.glob("#{@csv_file}*").each { |f|
      time = File.mtime(f).strftime('%Y%m%d_%H%M%S')
      FileUtils.mv f, "#{@csv_backup_file}.#{time}"
    }
    FileUtils.mv Dir.glob("#{@csv_backup_file}*").sort.reverse.first, @csv_file
  end

  # loads the data
  def load
    # Go and fetch eventual existing data from the file
    dputs(3) { "Starting to load #{@csv_file}" }
    @mutex.synchronize {
      cleanup if Dir.glob("#{@csv_file}*").size > 1
      ["#{@csv_file}"].concat(Dir.glob("#{@csv_backup_file}*").sort.reverse).each { |file|
        next if (!File.exists?(file) || File.size(file) == 0)
        begin
          dputs(3) { "Loading file #{file}" }
          data = {}
          File.open(file, 'r').readlines().each { |l|
            dputs(5) { "Reading line #{l}" }
            # Convert the keys in the lines back to Symbols
            data_parse = JSON.parse(l)
            data_csv = {}
            data_parse.each { |k, v|
              data_csv.merge!({k.to_sym => v})
            }
            # dputs( 5 ){ "Putting #{data_csv.inspect}" }
            did = data_csv[@data_field_id] = data_csv[@data_field_id].to_i
            data[did] = data_csv
          }
          dputs(5) { "data is now #{data.inspect}" }
          return data
        rescue JSON::ParserError
          log_msg :CSV, "Oups - couldn't load CSV for #{file}"
          FileUtils.rm file
        end
      }
    }

    return {}
  end

  def check_login(uid, pass)
    dputs(3) { "Searching in the CSV data" }
    index = @entity.find_index_by(:full_name, uid)
    if index
      dputs(3) { "Found index #{index} with pass #{@entity.data[index][:password]}" }
      return @entity.data[index][:password] == pass
    end
    dputs(3) { "Didn't find user with uid of #{uid}" }
    return false
  end

  def delete_all(local_only = false)
    # Making it in two steps is more secure... Luckily MacOSX doesn't mind
    # rm -rf /*
    # as a user ;)
    if not local_only
      dputs(2) { "Deleting #{@csv_dir}" }
      FileUtils.rm Dir.glob("#{@csv_file}")
      FileUtils.rm Dir.glob("#{@csv_backup_file}*")
    end
  end
end
