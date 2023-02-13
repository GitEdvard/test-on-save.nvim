local output_row = [[
        at uk.co.monotonic.testing.junit5.before.m2.Cafe.brew(Cafe.java:21)
]]
P(output_row)

local java_path, file_name, row = string.match(output_row, '([%.%a%d]*)%(([%.%a%d]+):(%d+)')
print(java_path)
print(file_name)
print(row)
local base_name = string.match(file_name, '([%a%d]+)%.')
print(base_name)
local path_truncated = string.match(java_path, '([%.%a%d]+)%.' .. base_name)
print(path_truncated)
local os_path = string.gsub(path_truncated, "%.", "/")
print(os_path)
