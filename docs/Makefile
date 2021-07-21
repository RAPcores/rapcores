# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build
TEROS_PATH ?= $(BUILDDIR)/teroshdl

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

teros-%:
	mkdir -p $(TEROS_PATH)
	teroshdl-hdl-documenter --recursive -i ../src/ -o html --outpath $(TEROS_PATH)
	cp $(TEROS_PATH)/index.html teros.html
	mkdir -p $(TEROS_PATH)/../$*/doc_internal
	cp $(TEROS_PATH)/doc_internal/* $(TEROS_PATH)/../$*/doc_internal


# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

