class String
  def normalize_numbers
    tr('０-９', '0-9')
  end
end
