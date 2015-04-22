class Statics < Entities
  def setup_data
    value_str :view_name
    value_str :data_str
  end

  def get(name)
    match_by_view_name(name) or
        create(:view_name => name, :data_str => '')
  end

  def get_hash(name)
    s = Statics.get(name)
    s.data_str.length == 0 and
        s.data_str = {}
    s.data_str
  end
end

# This way Statics is instantiated immediately, instead of
# any time later when calling QooxView.init
RPCQooxdooService.add_new_service( Statics,
                                   'Entities.Statics')