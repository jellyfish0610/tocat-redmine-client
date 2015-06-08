class TocatInvoice < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoices'
  self.element_name = 'invoice'
  add_response_method :http_response

  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end
  end

  schema do
    attribute 'id', :integer
    attribute 'external_id', :string
    attribute 'paid', :boolean
  end

  def editable?
    true
  end

  def activity
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}/activity?owner=invoice&owner_id=#{self.id}").body).each do |record|
        recipient = nil
        unless record["recipient_id"].nil?
          case record["recipient_type"]
          when "Invoice"
            recipient = TocatInvoice.find(record["recipient_id"].to_i)
          when "Order"
            recipient = TocatOrder.find(record["recipient_id"].to_i)
          when "User"
            recipient = TocatUser.find(record["recipient_id"].to_i)
          when "Team"
            recipient = TocatTeam.find(record["recipient_id"].to_i)
          end
        end
        records << OpenStruct.new(key: record["key"], recipient: recipient, parameters: record['parameters'], created_at: record['created_at'])
      end
       return records
     rescue
       return []
     end
  end

  def set_paid
    begin
      connection.post("#{self.class.prefix}/invoice/#{id}/paid")
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  def remove_paid
    begin
      connection.delete("#{self.class.prefix}/invoice/#{id}/paid")
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  protected

  def to_json(options = {})
    self.attributes[:team] = {:id => attributes[:team]}
    self.attributes.to_json(options)
  end
end
