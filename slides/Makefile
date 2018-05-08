all: publish

PHONY: all publish clean

SOURCES = $(wildcard src/*.md)

publish: $(SOURCES)
	nodeppt generate src -a

clean:
	rm -rf ./publish

#  vim:noexpandtab:
