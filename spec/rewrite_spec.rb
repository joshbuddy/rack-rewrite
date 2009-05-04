require 'spec_helper'

describe "Rack::Rewrite Rewriting" do

  it "should rewrite a path_info" do
    env = Rack::MockRequest.env_for('/test', :method => 'get')
    app = mock('app')
    app.should_receive(:call) { |resp|
      resp['PATH_INFO'].should == '/test/test'
      [200, {}, ["body"]]
    }
    
    Rack::Rewrite.new(app) { on(:path_info => '/test') { set(:path_info) { "/test#{path_info}" }; pass } }.call(env)
  end

  it "should arbitrarily add a new header" do
    env = Rack::MockRequest.env_for('/test?Happy-Land', :method => 'get')
    app = mock('app')
    app.should_receive(:call).and_return([200, {'Content-type' => 'text/html'}, ['mybody']])
    response = Rack::Rewrite.new(app) { on(:path_info => '/test') { act{ headers['My-special-header'] = query_string }; pass } }.call(env)
    response[1]['My-special-header'].should == 'Happy-Land'
  end

end
