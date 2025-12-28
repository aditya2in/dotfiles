require("josean.core")
require("josean.lazy")



local highlights = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "Pmenu",
    "SignColumn",
    "LineNr",
    "NonText",
}

for _, hl in ipairs(highlights) do
    vim.api.nvim_set_hl(0, hl, { bg = "none" })
end
