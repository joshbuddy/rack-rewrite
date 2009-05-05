$:.unshift(File.dirname(__FILE__))
require 'rack'
require 'rack_rewrite/actions'
require 'rack_rewrite/condition_set'

module Rack
  class Rewrite
    
    FailError = Class.new(RuntimeError)
    
    attr_accessor :path, :redirect, :headers
    
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
    
    def redirect(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      pattern = args.first
      @current_condition_set.actions << Action::Redirect.new(self, pattern || block, options[:status] || 302)
    end
    
    def call(env)
      @headers = {}
      catch(:pass) {
        env = call_conditions(env, @root)
        raise FailError.new
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