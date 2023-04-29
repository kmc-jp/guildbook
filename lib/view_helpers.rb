module Haml
  module Helpers
    def input_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-control'
      haml_tag :input, {name: attr, value: user[attr].first}.merge(opt)
    end
    def select_userattr(user, attr, opt = {})
      opt[:class] ||= 'form-select'
      haml_tag :select, {name: attr}.merge(opt) do
        haml_tag :option, selected: (user[attr].first=="TRUE"), value: "TRUE" do haml_concat "京都大学" end
        haml_tag :option, selected: (user[attr].first=="FALSE"), value: "FALSE" do haml_concat "その他" end
      end
    end
  end
end
