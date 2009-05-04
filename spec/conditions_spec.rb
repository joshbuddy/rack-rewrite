require 'spec_helper'

describe "Rack::Rewrite Conditions" do

  ['get', 'post', 'put', 'delete'].each do |method|

    it "should detect method #{method}" do
      env = Rack::MockRequest.env_for('/test', :method => method)
      app = mock('app')
      app.should_receive(:call).with(env)
      Rack::Rewrite.new(app) { on(:method => method) { pass } }.call(env)
    end
  end
  
  it "should detect a simple uri" do
    env = Rack::MockRequest.env_for('/test', :method => 'get')
    app = mock('app')
    app.should_receive(:call).with(env)
    Rack::Rewrite.new(app) { on(:uri => '/test') { pass } }.call(env)
  end

end
