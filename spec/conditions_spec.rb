require 'spec_helper'

describe "Rack::Rewrite Conditions" do

  ['get', 'post', 'put', 'delete'].each do |method|

    it "should detect method #{method}" do
      env = Rack::MockRequest.env_for('/test', :method => method)
      app = mock('app')
      app.should_receive(:call).with(env).and_return([200, {}, ["body"]])
      Rack::Rewrite.new(app) { on(:method => method) { pass }; fail }.call(env)
    end
  end
  
  it "should detect a simple path_info" do
    env = Rack::MockRequest.env_for('/test', :method => 'get')
    app = mock('app')
    app.should_receive(:call).with(env).and_return([200, {}, ["body"]])
    Rack::Rewrite.new(app) { on(:path_info => '/test') { pass }; fail }.call(env)
    proc { Rack::Rewrite.new(app) { on(:path_info => %r{^/test}) { pass }; fail }.call(Rack::MockRequest.env_for('/badtest', :method => 'get')) }.should raise_error
  end

  it "should fail on a simple path_info" do
    env = Rack::MockRequest.env_for('/test', :method => 'get')
    app = mock('app')
    proc { Rack::Rewrite.new(app) { on(:path_info => %r{^/test}) { pass }; fail }.call(Rack::MockRequest.env_for('/badtest', :method => 'get')) }.should raise_error
  end

  it "should detect a param in the query string" do
    env = Rack::MockRequest.env_for('/test?test=helpme', :method => 'get')
    app = mock('app')
    app.should_receive(:call).with(env).and_return([200, {}, ["body"]])
    Rack::Rewrite.new(app) { on(:params => {:test => 'helpme'}) { pass } }.call(env)
    proc { Rack::Rewrite.new(app) { on(:params => {:test => 'helpme2'}) { pass }; fail }.call(env) }.should raise_error
  end
  
end
