#! /usr/bin/make -f
# This Makefile is designed to be included, in a more comprehenisve makefile.
ifndef db
include configure.mk
endif

INFO::
	@echo Cali specific datasets

