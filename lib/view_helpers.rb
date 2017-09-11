module Haml
  module Helpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end
  end
end
