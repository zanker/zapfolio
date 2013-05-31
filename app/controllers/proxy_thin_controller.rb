# This is for development only.
# It acts as proxy pass in dev mode so we don't have to install nginx to test things
require "net/http"
class ProxyThinController < ApplicationController
  def proxy_pass
    url = URI.parse("http://localhost:5001/backend/#{params[:a]}")
    http = Net::HTTP.new(url.host, url.port)

    if request.post? or request.put? or request.delete?
      res = http.send("request_#{request.method.downcase}", url.path, generate_formdata(request.POST), {"Content-Type" => "application/x-www-form-urlencoded"})
    elsif request.get?
      res = http.request_get(url.path + "?#{generate_formdata(request.GET)}")
    end

    response.content_type = res.header["content-type"]
    render :text => res.body, :status => res.code
  end

  private
  def generate_formdata(hash, format=nil)
    data = ""

    hash.each do |k, v|
      k = format % k if format

      if v.is_a?(Hash)
        data << generate_formdata(v, "#{k}[%s]")
      elsif v.is_a?(Array)
        k = URI.encode("#{k}[]")
        v.each {|array_val| data << "#{k}=#{URI.encode(array_val)}&"}
      else
        data << "#{URI.encode(k)}=#{URI.encode(v)}&"
      end
    end

    data
  end
end