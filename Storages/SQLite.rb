=begin
SQLite-handler for Storagetypes. All data is stored in a common database,
and different subclasses get different tables.

Creation of table-columns is handled here
=end

require 'active_record'



class SQLite < StorageType
  def configure( config )
    dputs 3, "Configuring SQLite with #{@name}"
    @db_table = "stsql_#{@name.downcase}s"
    @db_class = "Stsql_#{@name.downcase}"
    ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3", :database => "data/sql.db" )
    super config
  end

  # Saves the data stored, optionally takes an index to say
  # which data needs to be saved
  def save( data )
    if @add_only
      dputs 1, "Not saving data for #{@name}"
    else
      File.open( "#{@csv_file}.tmp", "w"){|f|
        data_each(data){|d|
#          write_line( f, d )
        }
      }
    end
  end

  # Each new entry is directly stored, helping somewhat if the program or the
  # computer crashes
  def data_create( data )
    e = "#{@db_class}.create( #{data.inspect})"
    dputs 0, "Creating data: #{e.inspect}"
    eval( e )
  end

  # loads the data
  def load
    db_table, fields = @db_table, @fields
    ActiveRecord::Schema.define do
      if ! table_exists? db_table
        dputs 0, "Creating table #{db_table}"
        create_table db_table
      end
      fields.each{|f|
        dputs 1, "Checking for field #{f} in table #{db_table}"
        if not columns( db_table ).index{|c|
        c.name.to_s == f.to_s
        }
          dputs 1, "Adding column #{f}"
          add_column( db_table, f, :string )
        end
      }
    end
    eval( "class #{@db_class} < ActiveRecord::Base; end" )
    dputs 0, eval( "#{@db_class}.all").inspect
    return {}
  end

  def delete_all( local_only = false )
    db_table = @db_table
    dputs 0, "Deleting table #{db_table}"
    ActiveRecord::Schema.define do
      drop_table db_table.to_sym
    end
  end
end
