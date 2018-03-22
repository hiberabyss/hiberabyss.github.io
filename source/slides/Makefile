all: publish

PHONY: all publish

SOURCES = $(wildcard src/*.md)

publish: $(SOURCES)
	nodeppt generate src -a

#  vim:noexpandtab:
