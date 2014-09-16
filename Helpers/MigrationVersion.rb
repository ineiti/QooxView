# To change this template, choose Tools | Templates
# and open the template in the editor.

class MigrationVersions < Entities
  def setup_data
    value_str :class_name
    value_int :version
  end
  
  # These Entities don't migrate
  def migrate
  end
end

# This way MigrationVersions is instantiated immediatly, instead of
# any time later when calling QooxView.init
RPCQooxdooService.add_new_service( MigrationVersions,
                                   'Entities.MigrationVersions')