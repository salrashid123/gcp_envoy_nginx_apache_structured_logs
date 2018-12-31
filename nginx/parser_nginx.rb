require 'fluent/plugin/parser'

module Fluent
  module Plugin
    class NginxParser < Parser
      Plugin.register_parser('nginx', self)

      REGEXP = /^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>(?:[^\"]|\\.)*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<response_size>[^ ]*)(?: "(?<referer>(?:[^\"]|\\.)*)" "(?<agent>[^\"]*)"(?:\s+\"?(?<x_forwarded_for>[^\"]*)\"?)?) "(?<latency>[^\"]*)" "(?<http_x_cloud_trace_context>[^\"]*)"?$/
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
	      latency = (latency == '-') ? nil : latency

	      http_x_cloud_trace_context = m['http_x_cloud_trace_context']
        #http_x_cloud_trace_context = (http_x_cloud_trace_context == '-') ? nil : http_x_cloud_trace_context
        if http_x_cloud_trace_context == '-'
           trace = ''
	         span_id = ''
        else
	         trace = http_x_cloud_trace_context.split('/').first
           span_id = http_x_cloud_trace_context.split('/').last
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
          "http_x_cloud_trace_context" => trace,
          "span_id" => span_id
        }
        record["time"] = m['time'] if @keep_time_key

        yield time, record
      end
    end
  end
end
