require 'helper'
require 'omniauth-elitmus'

class StrategyTest < StrategyTestCase
  include OAuth2StrategyTests
end

class ClientTest < StrategyTestCase
  test 'has correct Elitmus site' do
    assert_equal 'https://www.elitmus.com', strategy.client.site
  end

  test 'has correct authorize url' do
    assert_equal 'https://www.elitmus.com/oauth/authorize', strategy.client.options[:authorize_url]
  end

  test 'has correct token url' do
    assert_equal 'https://www.elitmus.com/oauth/token', strategy.client.options[:token_url]
  end

  test 'should be initialized with symbolized client_options' do
    @options = { :client_options => { 'authorize_url' => 'https://www.elitmus.com' } }
    assert_equal 'https://www.elitmus.com', strategy.client.options[:authorize_url]
  end
end

class CallbackUrlTest < StrategyTestCase
  test "returns the default callback url" do
    url_base = 'http://myconsumerapp.authrequest.com'
    @request.stubs(:url).returns("#{url_base}/some/page")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/elitmus/callback", strategy.callback_url
  end

  test "returns path from callback_path option" do
    @options = { :callback_path => "/auth/some/custom/path/callback"}
    url_base = 'http://myconsumerapp.authrequest.com'
    @request.stubs(:url).returns("#{url_base}/page/path")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/some/custom/path/callback", strategy.callback_url
  end

  test "returns url from callback_url option" do
    url = 'http://myconsumerapp.authrequest.com/auth/elitmus/callback'
    @options = { :callback_url => url }
    assert_equal url, strategy.callback_url
  end
end

class AuthorizeParamsTest < StrategyTestCase

  test 'should include any authorize params passed in the :authorize_params option' do
    @options = { :authorize_params => { :foo => 'bar', :baz => 'zip' } }
    assert_equal 'bar', strategy.authorize_params['foo']
    assert_equal 'zip', strategy.authorize_params['baz']
  end

  test 'should include top-level options that are marked as :authorize_options' do
    @options = { :authorize_options => [:scope, :foo], :scope => 'bar', :foo => 'baz' }
    assert_equal 'bar', strategy.authorize_params['scope']
    assert_equal 'baz', strategy.authorize_params['foo']
  end
    
  test 'should exclude top-level options that are not passed' do
    @options = { :authorize_options => [:bar] }
    refute_has_key :bar, strategy.authorize_params
    refute_has_key 'bar', strategy.authorize_params
  end
  test 'includes default scope for public' do
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'public', strategy.authorize_params[:scope]
  end

  test 'includes display parameter from request when present' do
    @request.stubs(:params).returns({ 'display' => 'page' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'page', strategy.authorize_params[:display]
  end

  test 'includes auth_type parameter from request when present' do
    @request.stubs(:params).returns({ 'auth_type' => 'reauthenticate' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'reauthenticate', strategy.authorize_params[:auth_type]
  end

  test 'overrides default scope with parameter passed from request' do
    @request.stubs(:params).returns({ 'scope' => 'admin' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'admin', strategy.authorize_params[:scope]
  end


end

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'id' => '123' })
  end

  test 'returns the id from raw_info' do
    assert_equal '123', strategy.uid
  end
end

class InfoTestOptionalDataPresent < StrategyTestCase
   def setup
    super
    @raw_info ||= { 'name' => 'Fred Smith' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'returns the name' do
    assert_equal 'Fred Smith', strategy.info['name']
  end

  test 'returns the email' do
    @raw_info['email'] = 'fred@smith.com'
    assert_equal 'fred@smith.com', strategy.info['email']
  end

end

class InfoTestOptionalDataNotPresent < StrategyTestCase
  def setup
    super
    @raw_info = { 'name' => 'Fred Smith' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'has no email key' do
    refute_has_key 'email', strategy.info
  end

  test 'has no nickname key' do
    refute_has_key 'nickname', strategy.info
  end

  test 'has no first name key' do
    refute_has_key 'first_name', strategy.info
  end

  test 'has no last name key' do
    refute_has_key 'last_name', strategy.info
  end

  test 'has no location key' do
    refute_has_key 'location', strategy.info
  end

  test 'has no description key' do
    refute_has_key 'description', strategy.info
  end

  test 'has no urls' do
    refute_has_key 'urls', strategy.info
  end

  test 'has no verified key' do
    refute_has_key 'verified', strategy.info
  end
end

class RawInfoTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @appsecret_proof = 'appsecret_proof'
    @options = {:appsecret_proof => @appsecret_proof}
  end

  # test 'performs a GET to https://graph.facebook.com/me' do
  #   strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
  #   strategy.stubs(:access_token).returns(@access_token)
  #   params = {:params => @options}
  #   @access_token.expects(:get).with('/me', params).returns(stub_everything('OAuth2::Response'))
  #   strategy.raw_info
  # end

  # test 'performs a GET to https://graph.facebook.com/me with locale' do
  #   @options.merge!({ :locale => 'cs_CZ' })
  #   strategy.stubs(:access_token).returns(@access_token)
  #   strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
  #   @params = {:params => @options}
  #   @access_token.expects(:get).with('/me', @params).returns(stub_everything('OAuth2::Response'))
  #   strategy.raw_info
  # end

  # test 'performs a GET to https://graph.facebook.com/me with info_fields' do
  #   @options.merge!({:info_fields => 'about'})
  #   strategy.stubs(:access_token).returns(@access_token)
  #   strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
  #   params = {:params => {:appsecret_proof => @appsecret_proof, :fields => 'about'}}
  #   @access_token.expects(:get).with('/me', params).returns(stub_everything('OAuth2::Response'))
  #   strategy.raw_info
  # end

  # test 'returns a Hash' do
  #   strategy.stubs(:access_token).returns(@access_token)
  #  # strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
  #   raw_response = stub('Faraday::Response')
  #   raw_response.stubs(:body).returns('{ "ohai": "thar" }')
  #   raw_response.stubs(:status).returns(200)
  #   raw_response.stubs(:headers).returns({'Content-Type' => 'application/json' })
  #   oauth2_response = OAuth2::Response.new(raw_response)
  #   params = {:params => @options}
  #   @access_token.stubs(:get).with('/api/v1/me', params).returns(oauth2_response)
  #   p strategy.uid
  #  # assert_kind_of Hash, strategy.raw_info
  #  # assert_equal 'thar', strategy.raw_info['ohai']
  # end

  test 'returns an empty hash when the response is false' do
    strategy.stubs(:access_token).returns(@access_token)
    strategy.stubs(:appsecret_proof).returns(@appsecret_proof)
    oauth2_response = stub('OAuth2::Response', :parsed => false)
    params = {:params => @options}
    @access_token.stubs(:get).with('/me', params).returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
    assert_equal({}, strategy.raw_info)
  end

  test 'should not include raw_info in extras hash when skip_info is specified' do
    @options = { :skip_info => true }
    strategy.stubs(:raw_info).returns({:foo => 'bar' })
    refute_has_key 'raw_info', strategy.extra
  end
end



class CredentialsTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @access_token.stubs(:token)
    @access_token.stubs(:expires?)
    @access_token.stubs(:expires_at)
    @access_token.stubs(:refresh_token)
    strategy.stubs(:access_token).returns(@access_token)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.credentials
  end

  test 'returns the token' do
    @access_token.stubs(:token).returns('123')
    assert_equal '123', strategy.credentials['token']
  end

  test 'returns the expiry status' do
    @access_token.stubs(:expires?).returns(true)
    assert strategy.credentials['expires']

    @access_token.stubs(:expires?).returns(false)
    refute strategy.credentials['expires']
  end

  test 'returns the refresh token and expiry time when expiring' do
    ten_mins_from_now = (Time.now + 600).to_i
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns('321')
    @access_token.stubs(:expires_at).returns(ten_mins_from_now)
    assert_equal '321', strategy.credentials['refresh_token']
    assert_equal ten_mins_from_now, strategy.credentials['expires_at']
  end

  test 'does not return the refresh token when test is nil and expiring' do
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns(nil)
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end

  test 'does not return the refresh token when not expiring' do
    @access_token.stubs(:expires?).returns(false)
    @access_token.stubs(:refresh_token).returns('XXX')
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end
end

class ExtraTest < StrategyTestCase
  def setup
    super
    @raw_info = { 'name' => 'Fred Smith', 'email' => 'fred@smith.com', 'city' => 'bangalore' }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.extra
  end

  test 'contains raw info' do
    assert_equal({ 'raw_info' => @raw_info }, strategy.extra)
  end

end
