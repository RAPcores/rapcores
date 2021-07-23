#!/usr/bin/env python3

#
# Load TerosHDL (Colbiri) outputs into a sectioned RST file for integration with Sphinx
#
# python3 teros_sphinx_wrap.py <docs_internal path> <output rst>
#
# example:
#   python3 teros_sphinx_wrap.py ./_build/teroshdl/doc_internal ./internals.rst

import sys, os

#.. raw:: html
#  :file: teros.html
if (os.path.isdir(sys.argv[1]) and len(sys.argv) == 3 and sys.argv[2] != ""):
  internal_files = os.listdir(sys.argv[1])
  with open(sys.argv[2], 'w') as output:
    output.write("===============\nVerilog Modules\n===============\n\n")
    for file in internal_files:
      mod_name = os.path.splitext(file)[0]
      html_path = os.path.join(sys.argv[1], file)
      section_header = '-'*len(mod_name)+'\n'
      output.write(f"{section_header}{mod_name}\n{section_header}\n.. raw:: html\n  :file: {html_path}\n\n")
else:
  print("python3 teros_sphinx_wrap.py <docs_internal path> <output rst>")
