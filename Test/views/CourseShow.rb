# Also test automatical base-class creation

class CourseShow < View
  def layout
    show_block :names
  end
  
  def rpc_test( m, s, p )
    dputs 0, p.inspect
  end
end