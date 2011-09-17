class AView < View
  def layout
    set_data_class :Persons
    
    show_find :person_id
    show_block :block_one
    show_block :block_two
    show_int_ro :ro_int
    show_list_ro :ro_list, '[1,2,3]'
    show_list_ro :ro_list2
    show_fromto :duration
    show_list :worker, "Entities.Persons.list_name"
    
    @order = 60
  end
end
