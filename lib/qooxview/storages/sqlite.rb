=begin
SQLite-handler for Storagetypes. All data is stored in a common database,
and different subclasses get different tables.

Creation of table-columns is handled here
=end

require 'active_record'
require 'active_record/base'
require 'logger'


class SQLite < StorageType
  attr :db_class, :db_file

  def configure(config, name_base = 'stsql', name_file = 'sql.db')
    dputs(2) { "Configuring SQLite with #{@name}" }
    @db_table = "#{name_base}_#{@name.downcase}s"
    @db_class_name = "#{name_base.capitalize}_#{@name.downcase}"
    @db_class = nil
    @sqlite_dir = File.join($data_dir, get_config('data',
                                                  :StorageType, :data_dir))
    FileUtils.mkdir_p(@sqlite_dir)
    @name_file = name_file
    @db_file = File.join(@sqlite_dir, @name_file)
    # ActiveRecord::Base.logger = Logger.new('debug.log')
    ActiveRecord::Migration.verbose = false
    # ActiveRecord::Base.logger = Logger.new(STDERR)

    @mutex_es = Mutex.new

    dputs(4) { 'Opening database' }
    open_db

    super config
  end

  # Allows for debugging when wanting to load another db
  def close_db
    dputs(4) { "Closing db #{@name_file}" }
    ActiveRecord::Base.remove_connection
  end

  def open_db
    @mutex_es.synchronize {
      dputs(4) { "Opening connection to #{@name_file} - #{@sqlite_dir}" }
      ActiveRecord::Base.establish_connection(
          :adapter => 'sqlite3', :database => @db_file)

      dputs(4) { 'Initializing tables' }
      init_table

      dputs(4) { 'Getting Base' }
      eval("class #{@db_class_name} < ActiveRecord::Base; end")
      @db_class = eval(@db_class_name)
      dputs(4) { "db_class is #{db_class.inspect}" }

      @entries = {}
      @entries_save = {}
    }
  end

  # Saves the data stored, optionally takes an index to say
  # which data needs to be saved
  def save(data, notmp: false)
    @mutex_es.synchronize {
      dputs(3) { "Saving #{@entries_save.count} entries in #{@db_class}" }
      @entries_save.each_value { |v|
        dputs(4){"Saving #{db_class} #{v.inspect} - #{v.id}"}
        v.save
      }
      @entries_save = {}
    }
  end

  def set_entry(data, field, value)
    @mutex_es.synchronize {
      # dp "#{db_class} #{data.inspect} #{field} #{value}"
      dputs(5) { "Searching id #{data.inspect}" }
      if @entries[data]
        @entries[data].save
      end
      dat = @db_class.find(data)
      # dat = @db_class.first(:conditions => {@data_field_id => data})
      # dp @entries[data]
      # dp dat
      # dp data
      @entries[data] ||= dat
      if entry = @entries[data]
        entry.send("#{field}=", value)
        @entries_save[data] = entry
        return value
      else
        dputs(2) { "Didn't find id #{data.inspect}" }
        return nil
      end
    }
  end

  # Each new entry is directly stored, helping somewhat if the program or the
  # computer crashes
  def data_create(data)
    # dputs_func
    dputs(5) { "Creating early data #{data.inspect} with #{data.class}" }
    dputs(5) { "hello for #{data.inspect}" }
    dputs(5) { "db_class is #{@db_class.inspect}" }
    e = @db_class.create(data)
    dputs(5) { 'hello - 2' }
    new_id = e.attributes[@data_field_id.to_s]
    dputs(5) { "New id is #{new_id}" }
    data[@data_field_id] = new_id
    dputs(5) { "Creating data: #{e.inspect}" }
  end

  def init_table
    # dputs_func
    db_table, fields = @db_table, @fields
    dputs(3) { "Initializing #{@db_class_name} with db_table=#{db_table.inspect}" }
    ActiveRecord::Schema.define do
      new_table = false
      if !table_exists? db_table
        dputs(2) { "Creating table #{db_table}" }
        create_table db_table
        new_table = true
      end
      dputs(3) { "Fields is #{fields.inspect}" }
      fields.each_key { |f|
        dputs(3) { "Checking for field #{f} in table #{db_table}" }
        if not columns(db_table).index { |c|
          c.name.to_s == f.to_s }
          dputs(new_table ? 4 : 1) { "Adding column #{f} of type " +
              "#{fields[f][:dtype]} to table #{db_table}" }
          case fields[f][:dtype]
            when /int/, /entity/
              add_column(db_table, f, :integer)
            when /bool/
              add_column(db_table, f, :boolean)
            when /float/
              add_column(db_table, f, :float)
            when /date/
              add_column(db_table, f, :date)
            else
              add_column(db_table, f, :string)
          end
        end
      }
    end
    #    ActiveRecord::Base.logger = nil
  end

  # loads the data
  def load
    dputs(2) { "Loading data for #{@db_class_name}" }
    res = Hash[*@db_class.all.collect { |s|
                 @entries[s[@data_field_id]] = s
                 [s[@data_field_id].to_i, s.attributes.symbolize_keys]
               }.flatten(1)
    ]
    dputs(5) { "Result is: #{res.inspect}" }
    return res
  end

  def delete_all(local_only = false)
    if !local_only
      db_table = @db_table
      dputs(2) { "Deleting table #{db_table}" }
      ActiveRecord::Schema.define do
        if table_exists? db_table
          drop_table db_table.to_sym
        end
      end
      init_table
    end
  end

  def delete(id)
    entry = @db_class.find_by(id: id)
    if entry != nil
      entry.destroy
      @entries[id].delete
      if e = @entries_save[id]
        e.delete
      end
    end
  end

  def self.with_all_sqlites
    RPCQooxdooService.entities { |e|
      e.storage.each { |storage_name, storage_class|
        dputs(3) { "Found storage_name of #{storage_name.inspect}" }
        if storage_name.to_s =~ /^SQLite/
          dputs(3) { "Found #{e.name}::#{storage_name} as SQLite-something" }
          yield storage_class
        end
      }
    }
  end

  def self.dbs_close_all
    dputs(2) { 'Closing all dbs' }
    SQLite.with_all_sqlites { |sql|
      sql.close_db
    }
  end

  def self.dbs_open_load
    dputs(2) { 'Opening all dbs' }
    SQLite.with_all_sqlites { |sql|
      sql.open_db
    }
    dputs(2) { 'Loading all dbs' }
    RPCQooxdooService.entities { |e|
      e.is_loaded = false
    }
    RPCQooxdooService.entities { |e|
      unless e.is_loaded
        e.loading = true
        e.load
        e.loading = false
        u = Users.match_by_name('local')
        dputs(2){"User is #{u}"}
      end
    }
  end

  def self.dbs_open_load_migrate
    SQLite.dbs_open_load
    dputs(2) { 'Migrating all dbs' }
    RPCQooxdooService.migrate_all
  end
end
