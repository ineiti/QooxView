=begin
SQLite-handler for Storagetypes. All data is stored in a common database,
and different subclasses get different tables.

Creation of table-columns is handled here
=end

require 'active_record'
require 'active_record/base'
require 'logger'



class SQLite < StorageType
  attr :db_class
  
  def configure( config, name_base = "stsql", name_file = "sql.db" )
    dputs( 2 ){ "Configuring SQLite with #{@name}" }
    @db_table = "#{name_base}_#{@name.downcase}s"
    @db_class_name = "#{name_base.capitalize}_#{@name.downcase}"
    @db_class = nil
    %x[ mkdir -p data ]
    @name_file = name_file
    #    ActiveRecord::Base.logger = Logger.new('debug.log')
    ActiveRecord::Migration.verbose = false
    #ActiveRecord::Base.logger = Logger.new(STDERR)
    
    dputs( 4 ){ "Opening database" }
    open_db

    super config
  end
  
  # Allows for 
  def close_db
    ActiveRecord::Base.remove_connection
  end
  
  def open_db
    dputs( 4 ){ "Opening connection" }
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3", :database => "data/#{@name_file}" )

    dputs( 4 ){ "Initializing tables" }
    init_table
    
    dputs( 4 ){ "Getting Base" }
    eval( "class #{@db_class_name} < ActiveRecord::Base; end" )
    @db_class = eval( @db_class_name )
    dputs(4){"db_class is #{db_class.inspect}"}
    
    @entries = {}
    @entries_save = {}
  end

  # Saves the data stored, optionally takes an index to say
  # which data needs to be saved
  def save( data )
    dputs(3){"Saving #{@entries_save.count} entries in #{@db_class}"}
    @entries_save.each_value{|v|
      v.save
    }
    @entries_save = {}
  end

  def set_entry( data, field, value )
    dputs( 5 ){ "Searching id #{data.inspect}" }
    @entries[data] ||= @db_class.first( :conditions => { @data_field_id => data } )
    if entry = @entries[data]
      entry.send( "#{field}=", value )
      @entries_save[data] = entry
      return value
    else
      dputs( 2 ){ "Didn't find id #{data.inspect}" }
      return nil
    end
  end

  # Each new entry is directly stored, helping somewhat if the program or the
  # computer crashes
  def data_create( data )
    dputs( 5 ){ "Creating early data #{data.inspect} with #{data.class}" }
    dputs(5){"hello for #{data.inspect}"}
    dputs(5){"db_class is #{@db_class.inspect}"}
    e = @db_class.create( data )
    dputs(5){"hello - 2"}
    new_id = e.attributes[@data_field_id.to_s]
    dputs( 5 ){ "New id is #{new_id}" }
    data[@data_field_id] = new_id
    dputs( 5 ){ "Creating data: #{e.inspect}" }
  end

  def init_table
    db_table, fields = @db_table, @fields
    dputs(3){"Initializing #{@db_class_name} with db_table=#{db_table.inspect}"}
    ActiveRecord::Schema.define do
      new_table = false
      if ! table_exists? db_table
        dputs( 2 ){ "Creating table #{db_table}" }
        create_table db_table
        new_table = true
      end
      dputs( 3 ){ "Fields is #{fields.inspect}" }
      fields.each_key{|f|
        dputs( 3 ){ "Checking for field #{f} in table #{db_table}" }
        if not columns( db_table ).index{|c|
            c.name.to_s == f.to_s }
          dputs( new_table ? 4 : 1 ){ "Adding column #{f} to table #{db_table}" }
          case fields[f][:dtype]
          when "int"
            add_column( db_table, f, :integer )
          when "bool"
            add_column( db_table, f, :boolean )
          else
            add_column( db_table, f, :string )
          end
        end
      }
    end
    #    ActiveRecord::Base.logger = nil
  end

  # loads the data
  def load
    dputs( 2 ){ "Loading data for #{@db_class_name}" }
    res = Hash[ *@db_class.all.collect{|s|
        @entries[s[@data_field_id]] = s
        [ s[@data_field_id].to_i, s.attributes.symbolize_keys ]
      }.flatten(1)
    ]
    dputs( 5 ){ "Result is: #{res.inspect}" }
    return res
  end

  def delete_all( local_only = false )
    if ! local_only
      db_table = @db_table
      dputs( 2 ){ "Deleting table #{db_table}" }
      ActiveRecord::Schema.define do
        if table_exists? db_table
          drop_table db_table.to_sym
        end
      end
      init_table
    end
  end
  
  def self.with_all_sqlites
    RPCQooxdooService.entities{|e|
      e.storage.each{|storage_name, storage_class|
        dputs(3){"Found storage_name of #{storage_name.inspect}"}
        if storage_name.to_s =~ /^SQLite/
          dputs(3){"Found #{e.name}::#{storage_name} as SQLite-something"}
          yield storage_class
        end
      }
    }
  end
  
  def self.dbs_close_all
    dputs(2){"Closing all dbs"}
    SQLite.with_all_sqlites{|sql|
      sql.close_db
    }
  end
  
  def self.dbs_open_load
    dputs(2){"Opening all dbs"}
    SQLite.with_all_sqlites{|sql|
      sql.open_db
    }
    dputs(2){"Loading all dbs"}
    RPCQooxdooService.entities{|e|
      e.load
    }
  end
  
  def self.dbs_open_load_migrate
    SQLite.dbs_open_load
    dputs(2){"Migrating all dbs"}
    RPCQooxdooService.migrate_all    
  end
end
