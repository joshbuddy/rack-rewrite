require 'rack'
require 'CGI'
module Rack
  class Rewrite
    class Action
      
      def setup(env)
        @request = Rack::Request.new(env)
      end
      
      def respond_to?(method)
        @request.respond_to?(method) || super
      end
      
      def query_string=(params)
        env = @request.env
        env['QUERY_STRING'] = case params
        when Hash
          params.inject([]) { |qs, (k, v)| qs << "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"} * '&'
        else
          params
        end
        
        @request = Rack::Request.new(env)
      end
      
      def method_missing(method, *args, &block)
        @request.send(method, *args, &block)
      end

      class Pass < Action
        def call(env)
          throw :pass
        end
      end

      class Fail < Action
        def call(env)
          raise
        end
      end

      class Set < Action

        def initialize(variable, action)
          @variable = variable
          @action = action
        end

        def call(env)
          setup(env)
          self.send :"#{@variable}=", case @action
          when Proc
            instance_eval(&@action)
          else
            instance_eval(@action)
          end
          env
        end

      end

      class Do < Action
        def initialize(caller, action)
          @caller = caller
          @action = action
        end
        
        def method_missing(method, *args, &block)
          if respond_to?(method)
            super
          else
            @caller.send(method, *args, &block)
          end
        end
        
        def call(env)
          setup(env)
          case @action
          when Proc
            instance_eval(&@action)
          else
            instance_eval(@action)
          end
          env
        end

      end

      class Redirect < Action
        def initialize(caller, action)
          @caller = caller
          @action = action
        end

        def call(env)
          setup(env)
          @caller.redirect = [ 302, {'Location'=> case @action
          when Proc
            instance_eval(&@action)
          else
            instance_eval(@action)
          end}, []]
          throw :pass
        end
      end
      
    end

  end
end
    
    