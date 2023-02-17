local function merge_tables(...)
  local result = {}
  for _, t in ipairs({...}) do
    for k, v in pairs(t) do
      result[k] = v
    end
  end
  return result
end

local config = {
};

return merge_tables(
  config,
  require 'hyperlink',
  {}
);
