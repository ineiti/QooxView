class InitTests < Entities
  def setup_data
    value_str :text
  end

  def init
    InitTests.create(text: 'howdy')
  end

  def migrate_1(it)
    it.text = 'there'
  end
end
