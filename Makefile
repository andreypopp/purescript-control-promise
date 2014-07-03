SRC = $(shell find src -name '*.purs')
LIB = $(SRC:src/%.purs=lib/%.js)
