require 'soap/wsdlDriver'

module Interfax

  class Incoming

    class << self
      attr_accessor :username, :password, :mark_as_read, :limit

      def query(type, opts = {})
   
        result = SOAP::WSDLDriverFactory.new("https://ws.interfax.net/inbound.asmx?WSDL").create_rpc_driver.GetList(
          :Username => self.username,
          :Password => self.password,
          :MaxItems => opts[:MaxItems] || self.limit || 100,
          :MarkAsRead => opts[:MarkAsRead] || self.mark_as_read || false,
          :LType => type
        )
        return [] if result.nil? || !defined?(result.objMessageItem)
        result.objMessageItem.messageItem
      end

    end

  end

end