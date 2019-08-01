if Rails.env.production?
  class Rack::Attack
    throttle('/users/sign_in/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/users/sign_in' && req.post?
        req.remote_ip
      end
    end

    throttle('stats/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/stats'
        req.remote_ip
      end
    end

    throttle('contact/ip', limit: 5, period: 20.seconds) do |req|
      if req.path == '/contact' && req.post?
        req.remote_ip
      end
    end

    Rack::Attack.safelist('allow from localhost') do |req|
      IPService.ip_trusted?(req.remote_ip)
    end
  end
end
