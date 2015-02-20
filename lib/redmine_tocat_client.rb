Rails.configuration.to_prepare do
  # all internal files MUST be described here
  # classes
  require 'api/models/ticket'
  require 'api/models/order'
  require 'api/models/invoice'
  require 'api/models/user'
  require 'api/models/team'


  # patches
  require 'api/patches/active_resource_errors'
  require 'patches/user'

  # hooks

end

module RedmineTocatClient
  def self.settings
    if Setting[:plugin_redmine_tocat_client].blank?
      {}
    else
      Setting[:plugin_redmine_tocat_client]
    end
  end
end
