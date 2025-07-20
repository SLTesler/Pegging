local ffi = require("ffi")
ffi.cdef[[
    double fast_distance(double x1, double y1, double x2, double y2);
    double fast_dot(double x1, double y1, double x2, double y2);
    double fast_length(double x, double y);
]]

local fastmath = ffi.load("fastmath") -- On Windows, fastmath.dll must be in the same directory

return fastmath 