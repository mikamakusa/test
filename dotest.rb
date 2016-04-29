require 'rubygems'
require 'unirest'
require 'net/ssh'

ROOT_URL_DO = 'https://api.digitalocean.com/v2'
@token = gets.chomp
#@header = ({'Content-Type' => 'application/json', 'Authorization' 'Bearer %s' % token})
Unirest.default_header('Content-Type','application/json')
Unirest.default_header('Authorization','Bearer %s' % token)

@key = OpenSSL::PKey::RSA.generate(2048)

@os = gets.chomp; @version = gets.chomp
imageid = (((Unirest.get(ROOT_URL_DO+'/images')).body)['images']).each { |a|
  if a['distribution'].include?(@os) and a['name'].include?(@version)
    return a['id']
  end
}

@size = gets.chomp
sizeid = (((Unirest.get(ROOT_URL_DO+'/sizes')).body)['sizes']).each { |b|
  if b['slug'].include?(@size) and b['available'].include?('True')
    return b['slug']
  end
}

@region = gets.chomp
regionid = (((Unirest.get(ROOT_URL_DO+'/regions')).body)['regions']).each { |c|
  if c['slug'].include?(@region) and c['available'].include?('True')
    return c['slug']
  end
}

@action=%w(insert Remove reboot rebuild); @servername = gets.chomp; @number = gets.chomp; @network=%w(true, false)
if @action.include?('insert')
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
      @_body = '{"name": [%s, "%s"],"region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": %s}'% n1, (@servername + x), regionid, sizeid, imageid, @key.public_key, @net
    end
  else
    @_body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": %s}' % @servername, regionid, sizeid, imageid, @key.public_key, @net
  end
  Unirest.post ROOT_URL_DO + '/droplets', parameters: @_body

elsif @action.include?('remove')
  @serverid = gets.chomp
  Unirest.delete ROOT_URL_DO + '/droplets/%s' % @serverid

elsif @action.include?('reboot')
  @serverid = gets.chomp
  _body = '{"type":"reboot"}'
  Unirest.post ROOT_URL_DO + '/droplets/%s' % @serverid, parameters: _body

elsif @action.include?('rebuild')
  @os = gets.chomp; @version = gets.chomp; @serverid = gets.chomp
  imageid = (((Unirest.get(ROOT_URL_DO+'/images')).body)['images']).each { |a|
    if a['distribution'].include?(@os) and a['name'].include?(@version)
      return a['id']
    end
  }
  _body = '{"type":"rebuild","image":"%s"}' % imageid
  Unirest.post ROOT_URL_DO + '/droplets/%s' % @serverid, parameters: _body
end