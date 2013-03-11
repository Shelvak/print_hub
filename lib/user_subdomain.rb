class UserSubdomain
  def self.matches?(request)
    request.host == APP_CONFIG['local_server_ip']
  end 
end
