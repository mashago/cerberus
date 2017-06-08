
FILE_PATH:=../lib
TARGET:=$(FILE_PATH)/libcommon.a

CC:=gcc
CXX:=g++

C_FLAGS:=
CPP_FLAGS:=-O0 -Wall --std=c++11 -g

OS:=$(shell uname -s)
SRC:=$(wildcard *.cpp *.c)
OBJ:=$(patsubst %.cpp, %.o, $(patsubst %.c, %.o, $(SRC)))

USER_MACROS:=

INC:=. 
LIB_PATH:=.
LIB:=

default: $(TARGET)

info:
	@echo Platform: $(OS)
	@echo SRC: $(SRC)
	@echo OBJ: $(OBJ)

%.o: %.cpp
	$(CXX) $(CPP_FLAGS) $(addprefix -D, $(USER_MACROS)) $(addprefix -I, $(INC)) -c $< -o $@

%.o: %.c
	$(CC) $(C_FLAGS) $(addprefix -D, $(USER_MACROS)) $(addprefix -I, $(INC)) -c $< -o $@

$(TARGET): $(OBJ)
	mkdir -p $(FILE_PATH)
	ar -crus $(TARGET) $(OBJ)

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJ)
	rm -rf *.dSYM
