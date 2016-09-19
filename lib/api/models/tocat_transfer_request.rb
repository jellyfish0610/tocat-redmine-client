class TransferRequest < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transfer_requests'
  self.element_name = 'transfer_request'
  add_response_method :http_response
  include AuthTocat

  def pay
    connection.post("/#{self.class.element_name}/#{id}/pay",'', TocatUser.headers)
  end
  
  def available_recepients
    all_users = TocatUser.find(:all, params: {limit: 10000, tocat_role: 'view_transfers', search: "couch=1"}).select{|u| u.couch }
    all_users.map{|u| [u.name,u.id]}
  end
  def available_for_new
    an = available_recepients
    tocat_id = User.current.try(:tocat).try(:id)
    an.delete_if{|u| u[1] == tocat_id}
  end
  
  schema do
    attribute 'source_id', :decimal
    attribute 'description', :text
    attribute 'total', :decimal
  end
end
