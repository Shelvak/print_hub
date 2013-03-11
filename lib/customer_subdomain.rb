class CustomerSubdomain
  def self.matches?(request)
    request.subdomains.first == APP_CONFIG['public_host']
  end 
end
