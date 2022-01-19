require 'json'

require 'rest-client'
require 'concurrent-ruby'
require 'json-schema'

class WoWAPI

  class WoWAPI::Error < RuntimeError
    def initialize(message)
      super(message)
    end
  end

#--------------------------------------------------------------------------------------------------

  class WoWAPI::BadCredentialsError < WoWAPI::Error
    def initialize()
      super("Bad credentials")
    end
  end

#--------------------------------------------------------------------------------------------------

  class WoWAPI::UnexpectedJSONError < WoWAPI::Error
    def initialize(msg=nil)
      message = "Received unexpected JSON from Blizzard"
      if !msg.nil?
        message += ": #{msg}"
      end
      super(message)
    end
  end

#--------------------------------------------------------------------------------------------------

  class WoWAPI::UnexpectedAuthError < WoWAPI::Error
    def initialize()
      super("Could not refresh the access token")
    end
  end

#--------------------------------------------------------------------------------------------------

  class << self
    attr_accessor :AUTH_HOST
    attr_accessor :HOST
    attr_accessor :URIS
    attr_accessor :NAMESPACES
    attr_accessor :REGIONS
    attr_accessor :LOCALES
    attr_accessor :SCHEMAS
  end

#--------------------------------------------------------------------------------------------------

  self.AUTH_HOST = "battle.net"

#--------------------------------------------------------------------------------------------------

  self.HOST = "api.blizzard.com"

#--------------------------------------------------------------------------------------------------

  self.URIS = {
    realms: "connected-realm/index",
    realm: "connected-realm",
    item: "item"
  }

#--------------------------------------------------------------------------------------------------

  self.NAMESPACES = {
    realms: "dynamic",
    realm: "dynamic",
    item: "static"
  }

#--------------------------------------------------------------------------------------------------

  self.REGIONS = [
    :us,
    :eu,
    :kr,
    :tw
  ]

#--------------------------------------------------------------------------------------------------

  self.LOCALES = [
    # North America
    :en_US, # English - United States
    :es_MX, # Spanish - Mexico
    :pt_BR, # Portuguese - Brazil

    # Europe
    :en_GB, # English - Great Britain
    :es_ES, # Spanish - Spain
    :fr_FR, # French - France
    :ru_RU, # Russian - Russia
    :de_DE, # German - Germany
    # :pt_PT, # Portuguese - Portugal
    :it_IT, # Italian - Italia

    # Korea
    :ko_KR, # Korean - Korea

    # Taiwan
    :zh_TW, # Chinese - Taiwan

    # China
    :zh_CN # Chinese - China
  ]

#--------------------------------------------------------------------------------------------------

  self.SCHEMAS = {
    :realms => {
      "type": "object",
      "required": ["_links", "connected_realms"],
      "properties": {
        "_links": {
          "type": "object",
          "required": ["self"],
          "properties": {
            "href": {
              "type": "object",
              "required": "href",
              "properties": {
                "href": {"type": "string"}
              }
            }
          }
        },
        "_connected_realms": {
          "type": "array",
          "items": { "$ref": "#/$defs/realm" }
        }
      },
      "$defs": {
        "type": "object",
        "required": "href",
        "properties": {
          "href": {"type": "string"}
        }
      }
    }
  }

#--------------------------------------------------------------------------------------------------

  private
  def cb_call(context, args)
    if !@cb.nil?
      @cb.call(context, args)
    end
  end

#--------------------------------------------------------------------------------------------------

  private
  def get_api_uri(region, req_type, param=nil)
    common_part = "/data/wow/#{WoWAPI.URIS[req_type]}"
    if !param.nil?
      common_part += "/#{param}"
    end
    if @testing
      return "http://localhost:4567#{common_part}"
    else
      return "https://#{region.to_s}.#{WoWAPI.HOST}#{common_part}"
    end
  end

#--------------------------------------------------------------------------------------------------

  private
  def get(region, req_type, locale, namespace_region, param=nil)
    uri = get_api_uri(region, req_type, param)
    params = {namespace: "#{WoWAPI.NAMESPACES[req_type]}-#{namespace_region.to_s}",
              locale: locale.to_s,
              access_token: @token}

    wow_data = {}
    begin
      retry_cnt = 0
      try_again = false
      body = ""
      loop do
        cb_call(:get_before, {uri: uri, params: params, retry_cnt: retry_cnt})
        begin
          body = RestClient.get(uri, {params: params})
        rescue RestClient::Exceptions::OpenTimeout, Net::OpenTimeout => e
          cb_call(:get_error, {message: e.message, uri: uri, params: params, retry_cnt: retry_cnt})
          try_again = true
        rescue RestClient::TooManyRequests
          cb_call(:get_error, {message: e.message, uri: uri, params: params, retry_cnt: retry_cnt})
          try_again = true
          sleep(0.1)
        rescue OpenSSL::SSL::SSLError, RestClient::Exception
          raise
        end
        cb_call(:get_success, {result: wow_data, uri: uri, params: params, retry_cnt: retry_cnt})

        break if !try_again
        retry_cnt += 1 if try_again
        try_again = false
      end

      wow_data = JSON.parse(body)
      json_schema = WoWAPI.SCHEMAS[req_type]
      if !json_schema.nil?
        JSON::Validator.validate!(json_schema, wow_data)
      end

    rescue JSON::ParserError => e
      raise UnexpectedJSONError.new(e.message)
    rescue JSON::Schema::ValidationError => e
      raise UnexpectedJSONError.new("Validation failed: #{e.message}")
    end

    return wow_data
  end

#--------------------------------------------------------------------------------------------------

  private
  def group_ids(regions=WoWAPI.REGIONS)
    if regions.class == Symbol
      regions = [regions]
    end
    group_ids = {}
    regions.each do |region|
      result = get(region, :realms, :en_US, region)
      realms_index = result["connected_realms"]
      realms_index.each do |realm_link|
        match = /^.*\/(\d+)\?.*$/.match(realm_link["href"])
        if match.nil?
          raise UnexpectedJSONError.new("realm link not in expected format: #{realm_link["href"]}")
        end

        id = match[1].to_i
        group_ids[id] = region
      end
    end
    return group_ids
  end

#--------------------------------------------------------------------------------------------------

  public
  def realms(locales=WoWAPI.LOCALES, regions=WoWAPI.REGIONS)
    group_ids=group_ids(regions)
    if locales.class == Symbol
      locales = [locales]
    end
    pool = Concurrent::FixedThreadPool.new(100)
    realms_data = {}
    locales.each do |locale|
      group_ids.each_pair do |id, region|
        pool.post do
          begin
            connected_realms = get(region, :realm, locale, region, id)
            connected_realms["realms"].each do |realm|
              realms_data[realm["id"]] = {} if realms_data[realm["id"]].nil?
              realms_data[realm["id"]][locale] = {
                id: realm["id"],
                name: realm["name"],
                slug: realm["slug"],
                region: realm["region"]["id"],
                status: connected_realms["status"]["type"] == "UP" ? true : false,
                population: connected_realms["population"]["type"],
                category: realm["category"],
                locale: realm["locale"],
                timezone: realm["timezone"],
                realm_type: realm["type"]["type"]
              }
            end
          rescue => e
            cb_call(:unexpected_error, {message: e.message})
            raise
          end
        end
      end
    end
    pool.shutdown
    pool.wait_for_termination
    return realms_data
  end

#--------------------------------------------------------------------------------------------------

  public
  def item(item_id, locale)
    timestamp = Time.now
    item = get(@region, :item, locale, @region, item_id)
    elapsed = Time.now - timestamp
    if (elapsed < 0.01)
      sleep(0.01 - elapsed)
    end
    item_datas = {
      id: item_id,
      name: item["name"],
      quality: item["quality"]["type"],
      class_id: item["item_class"]["id"],
      subclass_id: item["item_subclass"]["id"],
      # binding: item["binding"]["type"]
    }
    match = /^.*static-(.*)-.*$/.match(item["_links"]["self"]["href"])
    # if match.nil?
    #   raise UnexpectedJSONError.new("link not in expected format: #{item["_links"]["self"]["href"]}")
    # end
    if !match.nil?
      item_datas[:version] = match[1]
    end
    return item_datas
  end

#--------------------------------------------------------------------------------------------------

  public
  def items(range=(1..100000), locales=WowAPI.LOCALES)
    pool = Concurrent::FixedThreadPool.new(100)
    items_datas = Concurrent::Hash.new

    if locales.size < 1
      raise ArgumentError.new "locales array is empty"
    end

    test_locale = locales.shift

    range.each do |item_id|
      pool.post do
        item_data = item(item_id, test_locale)
        items_datas[item_id] = {}
        items_datas[item_id][test_locale] = item_data
      end
    end

    pool.shutdown
    pool.wait_for_termination

    if locales.empty?
      return items_datas
    end

    pool = Concurrent::FixedThreadPool.new(100)
    items_datas.each_pair do |item_id, v|
      # WoWAPI.LOCALES.select{|k,v|k!=:en_US}.each do |locale|
      # [:fr_FR, :zn_CN].each do |locale|
      locales.each do |locale|
        pool.post do
          items_datas[item_id][locale] = {}
          items_datas[item_id][locale][:name] = "none"
          # items_datas[item_id][locale] = item(item_id, locale)
          item_data = item(item_id, locale)
          items_datas[item_id][locale] = item_data
        end
      end
    end
    pool.shutdown
    pool.wait_for_termination

    return items_datas
  end

#--------------------------------------------------------------------------------------------------

  def initialize(region, client_id, client_secret, testing=false, &block)
    if region.nil? || client_id.nil? || client_secret.nil?
      raise ArgumentError.new("At least one argument is nil")
    elsif !region.is_a?(Symbol) || !client_id.is_a?(String) || !client_secret.is_a?(String)
      raise ArgumentError.new("At least one argument has not the good type")
    elsif client_id.empty? || client_secret.empty?
      raise ArgumentError.new("At least one string argument is empty")
    end

    if testing
      auth_uri = "http://#{client_id}:#{client_secret}@localhost:4567/protected/oauth/token"
    else
      auth_uri = "https://#{client_id}:#{client_secret}@#{region.to_s}.#{WoWAPI.AUTH_HOST}/oauth/token"
    end

    begin
      response_json = RestClient.post(auth_uri, :grant_type => 'client_credentials')
      response_data = JSON.parse(response_json.body)
      if !response_data.is_a?(Hash) || !response_data["access_token"].is_a?(String) || response_data["access_token"].empty?
        raise UnexpectedJSONError
      end
    rescue RestClient::Unauthorized, RestClient::Forbidden
      raise BadCredentialsError
    rescue JSON::ParserError
      raise UnexpectedJSONError
    end

    @region = region
    @token = response_data["access_token"]
    @testing = testing
    @cb = block
  end

end
