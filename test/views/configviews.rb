class ConfigView1 < View
  def layout
    @functions_need = [ :take ]
  end
end

class ConfigView2 < View
  def layout
    @functions_reject = [ :over ]
  end
end

class ConfigView3 < View
  def layout
    @functions_need = [ :take ]
    @functions_reject = [ :over ]
    @values_need = { :value => :one }
  end
end
