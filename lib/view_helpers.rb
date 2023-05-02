module Haml
  module Helpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end
    def select_userattr(user, attr, values, show_default, opt = {})
      opt[:class] ||= 'form-select'
      haml_tag :select, {name: attr}.merge(opt) do
        if show_default
          haml_tag :option, selected: true, hidden: true, value: "" do haml_concat "--選択してください--" end
        end
        if (user[attr].size==0) then
          values.each{|k, v|
            haml_tag :option, value: k do haml_concat v end
          }
        else
          values.each{|k, v|
            if (user[attr].first.to_sym==k) then
              haml_tag :option, selected: true, value: k do haml_concat v end
            else
              haml_tag :option, value: k do haml_concat v end
            end
          }
        end
      end
    end
  end
end
