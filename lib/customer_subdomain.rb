class CustomerSubdomain
  def self.matches?(request)
    request.host =~ APP_CONFIG['public_host']
  end 
end
