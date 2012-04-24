
module Interfax

  class Base
    
    # Class methods
    
    class << self
      attr_accessor :username, :password
      attr_accessor :orientation, :page_size, :high_res, :fine_rendering

      def query(verb,verbdata,limit=-1)
        result = SOAP::WSDLDriverFactory.new("https://ws.interfax.net/dfs.asmx?WSDL").create_rpc_driver.FaxQuery(
          :Username => self.username,
          :Password => self.password,
          :Verb => verb,
          :VerbData => verbdata,
          :MaxItems => limit,
          :ResultCode => 0
        )
        return [] if result.nil? || !defined?(result.faxQueryResult)
        [*result.faxQueryResult.faxItemEx].map do |f| 
          FaxItem.new(
            f.transactionID,
            Time.parse(f.submitTime),
            Time.parse(f.postponeTime),
            f.destinationFax,
            f.duration,
            f.remoteCSID,
            f.pagesSent,
            f.status,
            f.subject,
            f.pagesSubmitted)
        end  
      end
      
      def find(*args)
        query("IN", args.join(','))
      end

      def last(limit=1)
        query("LE","999999999",limit)
      end
      
      def all()
        query("LE","999999999")
      end

    end

    # Instance methods

    def initialize(type="HTML",content=nil)
      @username = self.class.username
      @password = self.class.password
      @type = type.to_s.upcase
      @content = content
      @at = Time.now
      @recipients = nil
      @subject = "Change me"
      @retries = "0"

      @orientation = self.class.orientation || 'Portrait'
      @high_res = self.class.high_res || 'false'
      @fine_rendering = self.class.fine_rendering || 'true'
      @page_size = self.class.page_size || 'Letter'
    end
    
    def contains(content)
      @content = content
      self
    end
    
    def to(recipients)
      @recipients = [*recipients].join(";")
      self
    end
    
    def subject(subject)
      @subject = subject
      self
    end
    
    def retries(count)
      @retries = count.to_s
      self
    end
    
    def at(time)
      @at = time
      self
    end
  
    def fine_rendering(boolstring)
      @fine_rendering = boolstring
      self
    end

    def orientation(orientation)
      @orientation = orientation
      self
    end

    def high_res(boolstring)
      @high_res = boolstring
      self
    end

    def page_size(size)
      @page_size = size
      self
    end


    def summary
      { 
        :fax_numbers => @recipients, 
        :content => @content,
        :at => @at,
        :retries => @retries,
        :subject => @subject,
        :username => @username
      }
    end
    
    def deliver
      result = SOAP::WSDLDriverFactory.new("https://ws.interfax.net/dfs.asmx?WSDL").create_rpc_driver.SendfaxEx_2(
        :Username => @username,
        :Password => @password,
        :FileTypes => @type,
        :Postpone => @at,
        :RetriesToPerform => @retries,
        :FaxNumbers=> @recipients,
        :FilesData => @content,
        :FileSizes => @content.size,
        :Subject => @subject,
        :PageSize => @page_size,
        :PageOrientation => @orientation,
        :IsHighResolution => @high_res,
        :IsFineRendering => @fine_rendering
      )
      result ? result.sendfaxEx_2Result : nil
    end
    
  end

end
