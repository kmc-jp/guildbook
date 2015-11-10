require "#{File.dirname(__FILE__)}/lib/app"
require "#{File.dirname(__FILE__)}/lib/plugins/univ_plugin"
require "#{File.dirname(__FILE__)}/lib/plugins/group_plugin"
require "#{File.dirname(__FILE__)}/lib/plugins/checklist_plugin"
require "#{File.dirname(__FILE__)}/lib/plugins/adduser_plugin"
require "#{File.dirname(__FILE__)}/lib/plugins/help_plugin"
require "#{File.dirname(__FILE__)}/lib/plugins/users_json_plugin"
run GuildBook::App
