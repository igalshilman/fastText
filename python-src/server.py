#!/usr/bin/env python

from __future__ import print_function

import grpc
import service_pb2 
import service_pb2_grpc 

from flask import Flask
from flask import jsonify
from flask import request

def create_client():
    channel = grpc.insecure_channel('fasttext:50051')
    stub = service_pb2_grpc.SetsStub(channel)
    return stub

def expand_set(stub, words):
    req = service_pb2.Request(words=words)
    res = stub.ExpandWords(req)
    return [w for w in res.words] 

app = Flask(__name__)

@app.route('/')
def index():
    return "<h1>Hello, World!</h1>"

@app.route('/expand', methods=["POST"])
def expand():
	words = request.get_json()
	client = app.config['sets'] 
	result = expand_set(client, words)
	return jsonify(result)

if __name__ == '__main__':
    app.config['sets'] = create_client()
    app.run(host="0.0.0.0", debug=False)

