class CSV < StorageType

  def configure(config)
    dputs(3) { "Configuring CSV with #{@name}" }
    @csv_dir = "data/"
    @add_only = false
    super config
    @csv_file = @csv_dir + "#{@entity.class.name}.csv"
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
    if @add_only
      dputs(5) { "Not saving data for #{@name}" }
    else
      @mutex.synchronize {
        dputs(3) { "Saving data for #{@name} to #{@csv_dir} - #{@csv_file}" }
        FileUtils.mkdir_p @csv_dir unless File.exists? @csv_dir
        dputs(5) { "Data is #{data.inspect}" }
        tmpfile = "#{@csv_file}.tmp"
        File.open(tmpfile, "w") { |f|
          data_each(data) { |d|
            write_line(f, d)
          }
        }
        #%x[ sync ]
        dputs(5) { 'Moving file' }
        FileUtils.mv tmpfile, @csv_file
      }
    end
  end

  # Each new entry is directly stored, helping somewhat if the program or the
  # computer crashes
  def data_create(data)
    FileUtils.mkdir_p @csv_dir unless File.exists? @csv_dir
    tmpfile = "#{@csv_file}.tmp"
    File.exists? @csv_file and FileUtils.cp @csv_file, tmpfile
    File.open(tmpfile, 'a') { |f|
      write_line(f, data)
    }
    #%x[ sync ]
    dputs(5) { 'Moving file' }
    FileUtils.mv tmpfile, @csv_file
  end

  # loads the data
  def load
    data = {}
    # Go and fetch eventual existing data from the file
    dputs(3) { "Starting to load #{@csv_file}" }
    if File.exists?(@csv_file)
      begin
        File.open(@csv_file, "r").readlines().each { |l|
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
      rescue JSON::ParserError
        dputs(0) { "Oups - couldn't load CSV for #{@csv_file}" }
        raise StorageLoadError
      end
      dputs(5) { "data is now #{data.inspect}" }
    end

    return data
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
      FileUtils.rm Dir.glob("#{@csv_dir}/*csv")
    end
  end
end
