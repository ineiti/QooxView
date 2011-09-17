class BView < View
  def layout
    set_data_class :Persons

    show_find :person_id
    show_block :block_one

    @order = 30
  end
end