require 'spec_helper'

describe "Rack::Rewrite Rewriting" do

  it "should rewrite a uri" do
    env = Rack::MockRequest.env_for('/test', :method => 'get')
    app = mock('app')
    app.should_receive(:call) { |resp|
      resp['PATH_INFO'].should == '/test/test'
    }
    
    #.with(env.merge('PATH_INFO' => '/test/test'))
    Rack::Rewrite.new(app) { on(:uri => '/test') { set(:uri) { "/test#{uri}" }; pass } }.call(env)
  end

end
