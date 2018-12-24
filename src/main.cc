/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <iomanip>
#include <iostream>
#include <queue>
#include <stdexcept>
#include <grpc/grpc.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>
#include <grpcpp/server_context.h>
#include <grpcpp/security/server_credentials.h>
#include "service.grpc.pb.h"
#include "args.h"
#include "fasttext.h"

using namespace grpc;
using namespace fasttext;

class ServiceImpl final : public Sets::Service {

public:
  ServiceImpl(FastText& fasttext) : ft(fasttext) {}

private:

  Status ExpandWords(ServerContext* context, const Request* request,
                  Response* reply) override {

    doExpand(request, reply);
    return Status::OK;
  }

  void doExpand(const Request* in, Response* response) {
    real count = 0;
    Vector acc(ft.getDimension());
    Vector vec(ft.getDimension());

    acc.zero();

    for (int i = 0 ; i < in->words_size() ; i++) {
      const std::string& word = in->words(i);
      ft.getWordVector(vec, word);
      real norm = vec.norm();
      if (norm > 0) {
  	     vec.mul(1.0 / norm);
  	     acc.addVector(vec);
         count++;
      }
    }
    if (count > 0) {
  	  acc.mul(1.0 / count);
    }

    const auto& predictions = ft.getNN(acc, 100);
    for (auto& prediction : predictions) {
        response->add_words(prediction.second);
    }
  }

  FastText& ft;
};

int main(int argc, char** argv) {
  std::vector<std::string> args(argv, argv + argc);
  if (args.size() < 1) {
    exit(EXIT_FAILURE);
  }
  // init fastText
  FastText fasttext;
  fasttext.loadModel(args[2]);
  std::cout << "model loaded" << '\n';

  // start gRPC server
  ServiceImpl service(fasttext);
  ServerBuilder builder;
  builder.AddListeningPort("0.0.0.0:50051", grpc::InsecureServerCredentials());
  builder.RegisterService(&service);
  std::unique_ptr<Server> server(builder.BuildAndStart());

  // wait
  std::cout << "Server listening on " << ":50051" << std::endl;
  server->Wait();
}
