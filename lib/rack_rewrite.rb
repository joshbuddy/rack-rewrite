$:.unshift(File.dirname(__FILE__))
require 'rack'
require 'rack_rewrite/actions'

module Rack
  class Rewrite
    
    attr_accessor :path, :redirect, :headers
    
    class ConditionSet
      
      attr_reader :parent_set, :actions, :conditions
      
      def initialize(parent_set, conditions = nil)
        @parent_set = parent_set
        @conditions = conditions
        @actions = []
      end

      def satisfied?(env)
        if conditions
          
          uri_ok = conditions.key?(:uri) ? conditions[:uri] === env['PATH_INFO'] : true
          method_ok = conditions.key?(:method) ? conditions[:method] === env['REQUEST_METHOD'].downcase : true
          host_ok = conditions.key?(:host) ? conditions[:host] === env['HTTP_HOST'] : true
          port_ok = conditions.key?(:port) ? conditions[:port] === env['SERVER_PORT'].to_i : true
          scheme_ok = conditions.key?(:scheme) ? conditions[:scheme] === env['rack.url_scheme'] : true
          if conditions.key?(:params)
            req = Rack::Request.new(env)
            params_ok = true
            conditions[:params].each do |key, test|
              params_ok = test === req.params[key.to_s]
              break unless params_ok
            end
          else
            params_ok = true
          end
          #puts "uri_ok: #{uri_ok} method_ok #{method_ok} host_ok #{host_ok} port_ok #{port_ok} scheme_ok #{scheme_ok} for conditions #{conditions.inspect}"
          
          uri_ok && method_ok && host_ok && port_ok && scheme_ok && params_ok
        else
          true
        end
      end
      
      def inspect
        "#{id} .. conditions=#{conditions.inspect}\nactions=#{actions.inspect}"
      end
      
    end
    
    def initialize(app, options = {}, &block)
      @app = app
      @options = []
      @current_condition_set = @root = ConditionSet.new(nil)
      instance_eval(&block)
    end
    
    def on(conditions = {}, &block)
      @current_condition_set.actions << ConditionSet.new(@current_condition_set, conditions)
      @current_condition_set = @current_condition_set.actions.last
      instance_eval(&block)
      @current_condition_set = @current_condition_set.parent_set
    end

    def set(variable, pattern = nil, &block)
      @current_condition_set.actions << Action::Set.new(variable, pattern || block)
    end

    def act(&block)
      @current_condition_set.actions << Action::Do.new(self, block)
    end

    def pass
      @current_condition_set.actions << Action::Pass.new
    end
    
    def fail
      @current_condition_set.actions << Action::Fail.new
    end
    
    def redirect(pattern = nil, &block)
      @current_condition_set.actions << Action::Redirect.new(self, pattern || block)
    end
    
    def call(env)
      @headers = {}
      catch(:pass) {
        env = call_conditions(env, @root)
        raise
      }
      if @redirect
        redirect = @redirect
        @redirect = nil
        redirect
      else
        (status, headers, body) = @app.call(env)
        [status, headers.merge(@headers), body]
      end
    end
    
    def call_conditions(env, conditions_set)
      if conditions_set.satisfied?(env)
        conditions_set.actions.each_with_index do |act, index|
          break if @done
          case act
          when ConditionSet
            call_conditions(env, act)
          else
            env = act.call(env)
          end
        end
      end
      
    end
    
  end
end