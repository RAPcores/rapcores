#! /usr/bin/env julia

vals = map(x -> trunc(UInt8, x), abs.(round.(cos.(range(0, 2pi-(2pi)/256, length=256)).*255)))

open("cos_lut.bit", "w") do f
  for val in vals
    show(f, val)
    println(f)
  end
end