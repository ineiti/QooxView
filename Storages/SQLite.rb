=begin
SQLite-handler for Storagetypes. All data is stored in a common database,
and different subclasses get different tables.

Creation of table-columns is handled here
=end

require 'active_record'
require 'logger'



class SQLite < StorageType
  def configure( config )
    dputs 2, "Configuring SQLite with #{@name}"
    @db_table = "stsql_#{@name.downcase}s"
    @db_class_name = "Stsql_#{@name.downcase}"
    @db_class = nil
    %x[ mkdir -p data ]
    ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3", :database => "data/sql.db" )

    init_table
    eval( "class #{@db_class_name} < ActiveRecord::Base; end" )
    @db_class = eval( @db_class_name )

    super config
  end

  # Saves the data stored, optionally takes an index to say
  # which data needs to be saved
  def save( data )
    dputs 0, "Not implemented!"
  end

  def set_entry( data, field, value )
    dputs 5, "Searching id #{data}"
    entry = @db_class.first( :conditions => { 'movement_id' => data } )
    if entry
      entry.send( "#{field}=", value )
    entry.save!
    return value
    else
      dputs 2, "Didn't find id #{data.inspect}"
      return nil
    end
  end

  # Each new entry is directly stored, helping somewhat if the program or the
  # computer crashes
  def data_create( data )
    e = @db_class.create( data )
    dputs 5, "Creating data: #{e.inspect}"
  end

  def init_table
    db_table, fields = @db_table, @fields
    ActiveRecord::Schema.define do
      if ! table_exists? db_table
        dputs 2, "Creating table #{db_table}"
        create_table db_table
      end
      dputs 2, "Fields is #{fields.inspect}"
      fields.each_key{|f|
        dputs 3, "Checking for field #{f} in table #{db_table}"
        if not columns( db_table ).index{|c|
        c.name.to_s == f.to_s }
          dputs 5, "Adding column #{f}"
          case fields[f][:dtype]
          when "int"
            add_column( db_table, f, :integer )
          else
          add_column( db_table, f, :string )
          end
        end
      }
    end
    ActiveRecord::Base.logger = nil
  end

  # loads the data
  def load
    res = Hash[ *@db_class.all.collect{|s|
      [ s[@data_field_id].to_i, s.attributes.symbolize_keys ] }.flatten(1) ]
    dputs 5, "Result is: #{res.inspect}"
    return res
  end

  def delete_all( local_only = false )
    db_table = @db_table
    dputs 2, "Deleting table #{db_table}"
    ActiveRecord::Schema.define do
      if table_exists? db_table
        drop_table db_table.to_sym
      end
    end
    init_table
  end
end