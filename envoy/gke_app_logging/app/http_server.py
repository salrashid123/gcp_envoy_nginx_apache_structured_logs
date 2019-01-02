from flask import Flask, request, abort
from flask.logging import default_handler

import logging
import pprint
import os

project_id = os.getenv('GCP_PROJECT_ID', '-')

class RequestFormatter(logging.Formatter):
    def format(self, record):
        record.trace_id = ''
        record.span_id = ''
        if ('X-Cloud-Trace-Context' in request.headers):

          trace_id = request.headers['X-Cloud-Trace-Context']

          #trace_span_id = request.headers['X-Cloud-Trace-Context']
          #trace_id = trace_span_id.split('/')[0]
          #trace_id = 'projects/' + project_id + '/traces/' + trace_id      
          #if (len(trace_span_id.split('/') )>1):
          #  record.span_id = trace_span_id.split('/')[1]
          record.trace_id = trace_id    
        record.url = request.url
        record.remote_addr = request.remote_addr
        return super(RequestFormatter, self).format(record)

formatter = RequestFormatter(
    '{ "labels": { "name": "application" }, "SEVERITY": "%(levelname)s", "message":  "%(message)s", "logging.googleapis.com/trace": "%(trace_id)s", "logging.googleapis.com/spanId": "%(span_id)s" }'
)

default_handler.setFormatter(formatter)

app = Flask(__name__)
app.logger.setLevel(logging.INFO)
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

@app.route("/")
def hello():
    app.logger.info("hello")
    app.logger.info("world")    
    return "Hello World!"

@app.route("/_ah/health")
def health(): 
    return "ok"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000, debug=False,  threaded=True)
