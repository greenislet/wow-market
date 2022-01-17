require "rspec"

require "../wow-api.rb"

# ------------------------------------------------------------------------------

$LJUST = 80

# ------------------------------------------------------------------------------

def generate_name(id, locale)
  "#{id}-#{locale}"
end

# ------------------------------------------------------------------------------

def generate_item_json(id, locale)
  "{\"name\":\"#{generate_name(id, locale)}\"}"
end

# ------------------------------------------------------------------------------

def generate_media(id)
  "http://localhost:4567/medias?id=#{id}"
end

# ------------------------------------------------------------------------------

def generate_media_json(id)
  "{\"assets\":[{\"value\":\"#{generate_media(id)}\"}]}"
end

# ------------------------------------------------------------------------------

def main()
  thr = Thread.new do
    sleep(1)
      RSpec::Core::Runner::run(["--format", "documentation"])
    exit(0)
  end
end

# ------------------------------------------------------------------------------

describe WoWAPI do
  context "When user authenticates trough WoWAPI::authenticate(...) function" do

    before :each do
      TestAuth.returned_auth_result = true
      TestAuth.returned_status = 200
      TestAuth.returned_json = '{"access_token":"USQzbTzHBrcvk8hApYcnvFc2sDTiI8awGb"}'
      TestAuth.last_params = nil
    end

    # ARGUMENTS
    it "throws when one argument is nil" do
      expect { WoWAPI.new(nil, "test_id", "test_secret", true) }.to raise_error(ArgumentError)
      expect { WoWAPI.new(:eu, nil, "test_secret", true) }.to raise_error(ArgumentError)
      expect { WoWAPI.new(:eu, "test_id", nil, true) }.to raise_error(ArgumentError)
    end

    it "throws when one argument is not the good type" do
      expect { WoWAPI.new(42, "test_id", "test_secret", true) }.to raise_error(ArgumentError)
      expect { WoWAPI.new(:eu, 42, "test_secret", true) }.to raise_error(ArgumentError)
      expect { WoWAPI.new(:eu, "test_id", 42, true) }.to raise_error(ArgumentError)
    end

    it "throws when one of the string argument is not empty" do
      expect { WoWAPI.new(:eu, "", "test_secret", true) }.to raise_error(ArgumentError)
      expect { WoWAPI.new(:eu, "test_id", "", true) }.to raise_error(ArgumentError)
    end

    # add test to check if region is correct (is in region array)

    # AUTHENTICATION
    it "throws when the distant host denies the authentication" do
      TestAuth.returned_auth_result = false
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::BadCredentialsError)
    end

    it "throws when the distant host returns \"Unauthorized\"" do
      TestAuth.returned_auth_result = true
      TestAuth.returned_status = 403
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::BadCredentialsError)
    end

    # JSON
    it "throws when the received JSON is empty" do
      TestAuth.returned_json = ''
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    it "throws when the received JSON is invalid" do
      TestAuth.returned_json = '{'
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    it "throws when the received JSON is not a hash" do
      TestAuth.returned_json = '[]'
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    it "throws when the received JSON does not contain access token" do
      TestAuth.returned_json = '{}'
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    it "throws when the received token is not a string" do
      TestAuth.returned_json = '{"access_token":42}'
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    it "throws when the received token is an empty string" do
      TestAuth.returned_json = '{"access_token":""}'
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.to raise_error(WoWAPI::UnexpectedJSONError)
    end

    #
    it "does no throw when the distant host accepts the authentication and the returned JSON is valid" do
      expect { WoWAPI.new(:eu, "test_id", "test_secret", true) }.not_to raise_error
    end

    it "it returns a WoWAPI class" do
      expect(WoWAPI.new(:eu, "test_id", "test_secret", true)).to be_kind_of(WoWAPI)
    end

    it "the server gets the expected id/secret" do
      WoWAPI.new(:eu, "test_id", "test_secret", true)
      expect(TestAuth.received_id).to eq("test_id")
      expect(TestAuth.received_secret).to eq("test_secret")
    end

    it "params contains grant_type key" do
      WoWAPI.new(:eu, "test_id", "test_secret", true)
      expect(TestAuth.last_params).to have_key(:grant_type)
    end

    it "Grant_type header value is \"client_credentials\"" do
      WoWAPI.new(:eu, "test_id", "test_secret", true)
      expect(TestAuth.last_params[:grant_type]).to eq("client_credentials")
    end
  end

  context "When user fetch realm list through realms() method" do
    before :all do
      TestAuth.returned_auth_result = true
      TestAuth.returned_status = 200
      TestAuth.returned_json = '{"access_token":"USQzbTzHBrcvk8hApYcnvFc2sDTiI8awGb"}'
      TestAuth.last_params = nil
      @instance = WoWAPI.new(:eu, "test_id", "test_secret", true)
    end

    it "works" do
      TestAPI.realm_index_returned_json = '{'\
              '"_links": {'\
                '"self": {'\
                  '"href": "https://us.api.blizzard.com/data/wow/connected-realm/?namespace=dynamic-us"'\
                '}'\
              '},'\
              '"connected_realms": ['\
                '{'\
                  '"href": "https://us.api.blizzard.com/data/wow/connected-realm/4?namespace=dynamic-us"'\
                '},'\
                '{'\
                  '"href": "https://us.api.blizzard.com/data/wow/connected-realm/5?namespace=dynamic-us"'\
                '},'\
                '{'\
                  '"href": "https://us.api.blizzard.com/data/wow/connected-realm/9?namespace=dynamic-us"'\
                '}]'\
            '}'
      TestAPI.realm_returned_json = \
                '{'\
                  '"_links": {'\
                      '"self": {'\
                        '"href": "https://us.api.blizzard.com/data/wow/connected-realm/11?namespace=dynamic-us"'\
                      '}'\
                    '},'\
                    '"id": 11,'\
                    '"has_queue": false,'\
                    '"status": {'\
                      '"type": "UP",'\
                      '"name": "Up"'\
                    '},'\
                    '"population": {'\
                      '"type": "FULL",'\
                      '"name": "Full"'\
                    '},'\
                    '"realms": ['\
                      '{'\
                        '"id": 11,'\
                        '"region": {'\
                          '"key": {'\
                            '"href": "https://us.api.blizzard.com/data/wow/region/1?namespace=dynamic-us"'\
                          '},'\
                          '"name": "North America",'\
                          '"id": 1'\
                        '},'\
                        '"connected_realm": {'\
                          '"href": "https://us.api.blizzard.com/data/wow/connected-realm/11?namespace=dynamic-us"'\
                        '},'\
                        '"name": "Tichondrius",'\
                        '"category": "United States",'\
                        '"locale": "enUS",'\
                        '"timezone": "America/Los_Angeles",'\
                        '"type": {'\
                          '"type": "NORMAL",'\
                          '"name": "Normal"'\
                        '},'\
                        '"is_tournament": false,'\
                        '"slug": "tichondrius"'\
                      '}'\
                    '],'\
                    '"mythic_leaderboards": {'\
                      '"href": "https://us.api.blizzard.com/data/wow/connected-realm/11/mythic-leaderboard/?namespace=dynamic-us"'\
                    '},'\
                    '"auctions": {'\
                      '"href": "https://us.api.blizzard.com/data/wow/connected-realm/11/auctions?namespace=dynamic-us"'\
                    '}'\
                '}'

      expect{@instance.realms}.not_to raise_error
    end
  end
end
