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
  
  it "should let you create a new querystring from a hash" do
    env = Rack::MockRequest.env_for('/test?Happy=Land', :method => 'get')
    app = mock('app')
    app.should_receive(:call) { |resp|
      ['Happy=Land&more=query_goodness', 'more=query_goodness&Happy=Land'].should include(resp['QUERY_STRING'])
      [200, {}, ["body"]]
    }
    response = Rack::Rewrite.new(app) { on(:path_info => '/test') { set(:query_string) { params.merge(:more => :query_goodness)}; pass } }.call(env)
    
  end
  
  it "should let you create a new querystring from a string" do
    env = Rack::MockRequest.env_for('/test?Happy=Land', :method => 'get')
    app = mock('app')
    app.should_receive(:call) { |resp|
      resp['QUERY_STRING'].should == 'this_is_my_query_string'
      [200, {}, ["body"]]
    }
    response = Rack::Rewrite.new(app) { on(:path_info => '/test') { set(:query_string) { "this_is_my_query_string" }; pass } }.call(env)
    
  end
  
end
