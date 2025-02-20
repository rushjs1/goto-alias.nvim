--TODO:
--tests
--does .nuxt directory detection using string.concat have better preformance?
--newly created components do not seem to work

local M = {}

M.is_nuxt_project = false
M.original_definition = vim.lsp.buf.definition
M.nuxt_directory_path = ""

local default_check_directories = { "" }

M.setup = function(opts)
	opts = opts or {}

	local check_directories = vim.list_extend(default_check_directories, opts.check_directories or {})

	for _, directory in ipairs(check_directories) do
		if vim.fn.isdirectory(vim.loop.cwd() .. directory .. "/.nuxt") == 1 then
			M.is_nuxt_project = true
			if directory ~= "" then
				M.nuxt_directory_path = string.sub(directory, 2)
			end
		end
	end

	if not M.is_nuxt_project then
		return
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.vue" },
		callback = function()
			vim.lsp.buf.definition = M.watch
		end,
	})
end

M.watch = function()
	M.original_definition()

	vim.defer_fn(function()
		local line = vim.fn.getline(".")
		local path = string.match(line, '".-/(.-)"')
		local file = vim.fn.expand("%")

		if string.find(file, "components.d.ts") then
			vim.api.nvim_buf_delete(0, { force = false })
			vim.cmd("edit " .. M.nuxt_directory_path .. "/" .. path)
		elseif string.find(line, "components.d.ts") then
			vim.cmd("cclose")
			vim.cmd("edit " .. M.nuxt_directory_path .. "/" .. path)
		end
	end, 100)
end

return M
