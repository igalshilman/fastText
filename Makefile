#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
GRPC_INCLUDE = /usr/local/include/grpc++
GRPC_LIB = /usr/local/lib
PROTOBUF_SRC = /usr/local/include/google/protobuf
GRPC_CPP_PLUGIN = /usr/local/bin/grpc_cpp_plugin 
CXX = c++
CXXFLAGS = -pthread -std=c++0x -march=native -I$(GRPC_INCLUDE) -I$(PROTOBUF_SRC)
OBJS = args.o dictionary.o productquantizer.o matrix.o qmatrix.o vector.o model.o utils.o meter.o fasttext.o service.pb.o service.grpc.pb.o
INCLUDES = -I.
LDFLAGS = -lgpr
LDFLAGS += `pkg-config --libs protobuf grpc++ grpc`\
           -Wl,--no-as-needed -lgrpc++_reflection -Wl,--as-needed\
           -ldl

opt: CXXFLAGS += -O3 -funroll-loops
opt: fasttext

coverage: CXXFLAGS += -O0 -fno-inline -fprofile-arcs --coverage
coverage: fasttext

debug: CXXFLAGS += -g -O0 -fno-inline
debug: fasttext

args.o: src/args.cc src/args.h
	$(CXX) $(CXXFLAGS) -c src/args.cc

dictionary.o: src/dictionary.cc src/dictionary.h src/args.h
	$(CXX) $(CXXFLAGS) -c src/dictionary.cc

productquantizer.o: src/productquantizer.cc src/productquantizer.h src/utils.h
	$(CXX) $(CXXFLAGS) -c src/productquantizer.cc

matrix.o: src/matrix.cc src/matrix.h src/utils.h
	$(CXX) $(CXXFLAGS) -c src/matrix.cc

qmatrix.o: src/qmatrix.cc src/qmatrix.h src/utils.h
	$(CXX) $(CXXFLAGS) -c src/qmatrix.cc

vector.o: src/vector.cc src/vector.h src/utils.h
	$(CXX) $(CXXFLAGS) -c src/vector.cc

model.o: src/model.cc src/model.h src/args.h
	$(CXX) $(CXXFLAGS) -c src/model.cc

utils.o: src/utils.cc src/utils.h
	$(CXX) $(CXXFLAGS) -c src/utils.cc

meter.o: src/meter.cc src/meter.h
	$(CXX) $(CXXFLAGS) -c src/meter.cc

fasttext.o: src/fasttext.cc src/*.h
	$(CXX) $(CXXFLAGS) -c src/fasttext.cc

service.grpc.pb.o: src/service.grpc.pb.cc src/service.grpc.pb.h
	$(CXX) $(CXXFLAGS) -c src/service.grpc.pb.cc

service.pb.o: src/service.pb.cc src/service.pb.h
	$(CXX) $(CXXFLAGS) -c src/service.pb.cc

src/service.pb.cc:
	protoc --cpp_out=src/ service.proto

src/service.grpc.pb.cc:
	protoc --grpc_out=src/ --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN) service.proto

fasttext: $(OBJS) src/fasttext.cc
	$(CXX) $(CXXFLAGS) $(OBJS) $(LDFLAGS) src/main.cc -o fasttext

grpc:
	rm -f src/service.grpc.pb.*
	rm -f src/service.pb.*
	protoc --cpp_out=src/ service.proto
	protoc --grpc_out=src/ --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN) service.proto

clean:
	rm -rf *.o *.gcno *.gcda fasttext
	rm -rf src/service*pb.*
