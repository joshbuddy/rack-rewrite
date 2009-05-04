module Rack
  class Rewrite
    class Action
      
      def uri
        @env['PATH_INFO']
      end
      
      def uri=(uri)
        @env['PATH_INFO'] = uri
        update_uri_qs
      end
      
      def query_string
        @env['QUERY_STRING']
      end

      def query_string=(query_string)
        @env['QUERY_STRING'] = query_string
        update_uri_qs
      end
      
      def update_uri_qs
        @env['REQUEST_PATH'] = uri
        @env['REQUEST_URI'] = query_string.empty? ? uri : (uri + '?' + query_string)
      end
      
      def method
        @env['REQUEST_METHOD']
      end
      
      def method=(method)
        @env['REQUEST_METHOD'] = method.to_s.upcase
      end
      
      def host
        @env['HTTP_HOST']
      end
      
      def host=(host)
        @env['HTTP_HOST'] = host
      end
      
      def port
        @env['SERVER_PORT']
      end
      
      def port=(port)
        @env['SERVER_PORT'] = port.to_s
      end
      
      def scheme
        @env['rack.url_scheme']
      end
      
      def scheme=(scheme)
        @env['rack.url_scheme'] = scheme
      end
      
      def setup(env)
        @env = env
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
        def initialize(action)
          @action = action
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
    
    