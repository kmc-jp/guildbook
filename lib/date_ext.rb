require 'date'

class Date
  def academic_year
    month < 4 ? year - 1 : year
  end
end

class DateTime
  def generalized_time
    strftime('%Y%m%d%H%M%S%z')
  end
end
