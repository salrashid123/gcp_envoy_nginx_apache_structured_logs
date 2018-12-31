require 'fluent/plugin/parser'

module Fluent
  module Plugin
    class Apache2Parser < Parser
      Plugin.register_parser('apache2', self)

      REGEXP = /^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>(?:[^\"]|\\.)*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<response_size>[^ ]*)(?: "(?<referer>(?:[^\"]|\\.)*)" "(?<agent>[^\"]*)"(?:\s+\"?(?<x_forwarded_for>[^\"]*)\"?)?) "(?<latency>[^\"]*)" "(?<x_cloud_trace_context>[^\"]*)"?$/
      TIME_FORMAT = "%d/%b/%Y:%H:%M:%S %z"

      def initialize
        super
        @mutex = Mutex.new
      end

      def configure(conf)
        super
        @time_parser = time_parser_create(format: TIME_FORMAT)
      end

      def patterns
        {'format' => REGEXP, 'time_format' => TIME_FORMAT}
      end

      def parse(text)
        m = REGEXP.match(text)
        unless m
          yield nil, nil
          return
        end

        host = m['host']
        host = (host == '-') ? nil : host

        user = m['user']
        user = (user == '-') ? nil : user

        time = m['time']
        time = @mutex.synchronize { @time_parser.parse(time) }

        method = m['method']
        path = m['path']

        code = m['code'].to_i
        code = nil if code == 0

        response_size = m['response_size']
        response_size = (response_size == '-') ? nil : response_size.to_i

        referer = m['referer']
        referer = (referer == '-') ? nil : referer

        agent = m['agent']
        agent = (agent == '-') ? nil : agent

        x_forwarded_for = m['x_forwarded_for']
        x_forwarded_for = (x_forwarded_for == '-') ? nil : x_forwarded_for

        latency = m['latency']
	      latency = (latency == '-') ? nil : (Float(latency)/1000).to_s

        x_cloud_trace_context = m['x_cloud_trace_context']
        #x_cloud_trace_context = (x_cloud_trace_context == '-') ? nil : x_cloud_trace_context
        if x_cloud_trace_context == '-'
           trace = ''
	         span_id = ''
        else
	         trace = x_cloud_trace_context.split('/').first
           span_id = x_cloud_trace_context.split('/').last
        end

        record = {
          "host" => host,
          "user" => user,
          "method" => method,
          "path" => path,
          "code" => code,
          "response_size" => response_size,
          "referer" => referer,
          "agent" => agent,
	        "x_forwarded_for" => x_forwarded_for,
	        "latency" => latency,
          "x_cloud_trace_context" => trace,
          "span_id" => span_id
        }
        record["time"] = m['time'] if @keep_time_key

        yield time, record
      end
    end
  end
end
