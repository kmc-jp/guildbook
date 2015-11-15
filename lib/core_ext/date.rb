require 'date'

class Date
  def academic_year
    month < 4 ? year - 1 : year
  end
end
