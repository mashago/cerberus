TARGET:= ../lib/libcommon.a

default: platform all

OS:=$(shell uname -s)

CXX:=g++
CFLAG:=-Wall -g

SRC:=$(wildcard *.cpp)
OBJ:=$(patsubst %.cpp, %.o, $(SRC))

platform:
	@echo Platform: $(OS)

clean:
	rm -rf $(TARGET) $(OBJ)
	rm -rf *.dSYM

net_server.o: net_server.cpp 
	g++ -c -o $@ $^

libcommon.a: net_server.o
	ar -crus ../lib/$@ $^

%.o: %.cpp
	$(CXX) $(CFLAG) -c $< -o $@
	

all: $(OBJ)
	ar -crus $(TARGET) $(OBJ)
