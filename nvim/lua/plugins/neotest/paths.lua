-- Shared file-ownership rules for the JS/TS adapters.
--
-- jest, vitest and playwright all match `*.test.ts` / `*.spec.ts` by default, so
-- a repo with unit tests and e2e tests would have every adapter claim every file.
-- Split them by location instead: playwright owns anything under an e2e
-- directory, jest/vitest own everything else.
local M = {}

M.e2e_dir_patterns = { "/e2e/", "/e2e%-tests/", "/playwright/", "/__e2e__/" }

--- True when the file lives in an end-to-end test directory.
---@param file string
---@return boolean
function M.is_e2e(file)
	for _, pattern in ipairs(M.e2e_dir_patterns) do
		if file:find(pattern) then
			return true
		end
	end
	return false
end

--- True for JS/TS files named like tests (`.test.`, `.spec.`, or inside `__tests__/`).
---@param file string
---@return boolean
function M.looks_like_js_test(file)
	if file:find("/__tests__/") and file:match("%.[cm]?[jt]sx?$") then
		return true
	end
	return file:match("%.test%.[cm]?[jt]sx?$") ~= nil or file:match("%.spec%.[cm]?[jt]sx?$") ~= nil
end

--- Unit test file (jest / vitest): looks like a test and is not under an e2e directory.
function M.is_unit_test_file(file)
	return file ~= nil and M.looks_like_js_test(file) and not M.is_e2e(file)
end

--- End-to-end test file (playwright): looks like a test and is under an e2e directory.
function M.is_e2e_test_file(file)
	return file ~= nil and M.looks_like_js_test(file) and M.is_e2e(file)
end

return M
