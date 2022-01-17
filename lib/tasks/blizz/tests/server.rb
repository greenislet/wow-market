require 'sinatra/base'

# ------------------------------------------------------------------------------

$LJUST = 80

# ------------------------------------------------------------------------------

class TestAPI < Sinatra::Base

  class << self
    attr_accessor :last_params

    attr_accessor :item_called
    attr_accessor :media_called
    attr_accessor :realm_index_called
    attr_accessor :realm_called

    attr_accessor :item_returned_json
    attr_accessor :media_returned_json
    attr_accessor :realm_index_returned_json
    attr_accessor :realm_returned_json

    attr_accessor :status
    attr_accessor :reset_status

    attr_accessor :first_req_time
    attr_accessor :last_req_time
    attr_accessor :nb_reqs

    attr_accessor :times
  end

  self.item_called = 0
  self.media_called = 0
  self.realm_index_called = 0
  self.realm_called = 0

  # def realm_returned_json(idx)
  #
  # end

  self.status = 200
  self.reset_status = false

  self.nb_reqs = 0

  self.times = []



  def self.reset()
    self.item_called = 0
    self.media_called = 0
    self.status = 200
    self.reset_status = false
    self.nb_reqs = 0
    self.times = []
  end

  def self.count()
    now = Time.now
    if TestAPI.nb_reqs == 0
      TestAPI.first_req_time = now
    end
    TestAPI.last_req_time = now
    TestAPI.times << now
    TestAPI.nb_reqs += 1
  end

  get '/data/wow/item/:id' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.item_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    TestAPI.item_returned_json.call(params[:id], params[:locale])
  end

  get '/data/wow/media/item/:id' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.media_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    TestAPI.media_returned_json.call(params[:id])
  end

  get '/data/wow/connected-realm/index' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.realm_index_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    return TestAPI.realm_index_returned_json
  end

  get '/data/wow/connected-realm/:idx' do
    TestAPI.count()
    TestAPI.last_params = params.clone
    TestAPI.realm_called += 1
    status TestAPI.status
    if TestAPI.reset_status == true
      TestAPI.status = 200
    end
    return TestAPI.realm_returned_json
  end

end

# ------------------------------------------------------------------------------

class TestAuth < Sinatra::Base

  class << self
    attr_accessor :nb_auth
    attr_accessor :last_params
    attr_accessor :returned_json
    attr_accessor :received_id
    attr_accessor :received_secret
    attr_accessor :returned_auth_result
    attr_accessor :returned_status
  end

  self.nb_auth = 0
  self.returned_status = 200
  self.returned_auth_result = true

  def self.reset()
    self.nb_auth = 0
  end

  post '/oauth/token' do
    TestAuth.nb_auth += 1
    TestAuth.last_params = params.clone
    status TestAuth.returned_status
    return TestAuth.returned_json
  end

  use Rack::Auth::Basic, "Protected Area" do |username, password|
    TestAuth.received_id = username
    TestAuth.received_secret = password
    TestAuth.returned_auth_result
  end

end
