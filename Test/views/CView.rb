class CView < View
  def layout
    set_data_class :Persons
    
    gui_vbox do
      gui_hbox do
        show_find :person_id
        show_button :new
      end
      gui_hbox do
        show_block :block_one
        show_arg :name, :callback => "yes"
      end
      gui_window :cview do
        show_int :counter, :min => 10, :max => 20
        show_str_hidden :street
      end
    end
    
    @order = 40
  end
end
