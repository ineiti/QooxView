class PrintView < View
  include PrintButton

  def layout
    @order = 50
    gui_vbox do
      show_print :print_student
    end
  end
end
