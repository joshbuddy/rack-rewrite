module Rack
  class Rewrite
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

          uri_ok && method_ok && host_ok && port_ok && scheme_ok && params_ok
        else
          true
        end
      end
  
    end
  end
end