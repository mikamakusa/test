require 'rubygems'
require 'unirest'
require 'net/ssh'

class Digitalocean
  @header = ({'Content-Type' => 'application/json',
              :Authorization => 'Bearer %s'%token})

  def initialize(token, os, version, size, region, servername, serverid, number, network)
    @token = token
    @os = os
    @version = version
    @size = size
    @region = region
    @servername = servername
    @serverid = serverid
    @number = number
    @network = network
  end

  def token
    @token = gets.chomp
  end

  def image
    (((Unirest.get(ROOT_URL_DO+'/images', headers: header)).body)['images']).each { |a|
      if a['distribution'].include?(@os) and a['name'].include?(@version)
        return a['id']
      end
    }
  end

  def flavor
    (((Unirest.get(ROOT_URL_DO+'/sizes', headers: header)).body)['sizes']).each { |b|
      if b['slug'].include?(@size) and b['available'].include?('True')
        return b['slug']
      end
    }
  end

  def place
    (((Unirest.get(ROOT_URL_DO+'/regions', headers: header)).body)['regions']).each { |c|
      if c['slug'].include?(@region) and c['available'].include?('True')
        return c['slug']
      end
    }
  end

  def droplets
    def insert
      key = OpenSSL::PKey::RSA.generate(2048)
      @os = gets.chomp; @version = gets.chomp; @servername = gets.chomp; @size = gets.chomp
      @region = gets.chomp; @number = gets.chomp; @network = gets.chomp
      _place = place; _flavor = flavor; _image = image
      if @network == true or @network == false
        if true
          @net = 'true'
        else
          @net = 'null'
        end
      end
      if @number.is_a? Integer && @number != 0 && @number < 10
        x = 0
        while x < @number - 1
          n1 += '"'+@servername + x +'"'+', '
          @_body = '{"name": [%s, "%s"],"region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": %s}'% n1, (@servername + x), _place, _flavor, _image, key.public_key, @net
        end
      else
        @_body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": %s}' % @servername, _place, _flavor, _image, key.public_key, @net
      end
      Unirest.get(ROOT_URL_DO+'/regions', headers: @header, @_body)
    end

    def remove
      @serverid = gets.chomp
      Unirest.delete(ROOT_URL_DO + '/droplets/%s' % @serverid, headers: @header)
    end

    def reboot
      @serverid = gets.chomp
      _body = '{"type":"reboot"}'
      Unirest.post(ROOT_URL_DO + '/droplets/%s' % @serverid, headers: @header, _body)
    end

    def rebuild
      @os = gets.chomp; @version = gets.chomp; @serverid = gets.chomp; _image = image
      _body = '{"type":"rebuild","image":"%s"}' % _image
      Unirest.post(ROOT_URL_DO + '/droplets/%s' % @serverid, headers: @header, _body)
    end
  end
end