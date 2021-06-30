#! /usr/bin/env julia

function check_spdx(dir, spdx_header="// SPDX-License-Identifier: ISC")
  for file in readdir(dir, join=true)
    if isfile(file) && endswith(file, ".v")
      content = read(file, String)
      if !contains(content, spdx_header)
        write(file, spdx_header*"\n"*content)
        println("added SPDX header to $file")
      end
    elseif isdir(file)
      check_spdx(file)
    end
  end
end

check_spdx("src")