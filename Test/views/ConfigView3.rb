class ConfigView3 < View
  def layout
    @functions_need = [ :take ]
    @functions_reject = [ :over ]
  end
end
