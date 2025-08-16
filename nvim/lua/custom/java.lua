local jdtls_ok, jdtls = pcall(require, "jdtls")
if not jdtls_ok then
	vim.notify("nvim-jdtls not found (install via Mason: jdtls)", vim.log.levels.ERROR)
	return
end

-- Prepare fake Maven project for Firenvim Java
local function ensure_firenvim_project()
	local proj_dir = vim.fn.expand("~/java-firenvim")
	if vim.fn.isdirectory(proj_dir) == 0 then
		vim.fn.mkdir(proj_dir, "p")
		local pom = {
			"<project>",
			"  <modelVersion>4.0.0</modelVersion>",
			"  <groupId>dummy</groupId>",
			"  <artifactId>dummy</artifactId>",
			"  <version>1.0.0</version>",
			"</project>",
		}
		vim.fn.writefile(pom, proj_dir .. "/pom.xml")
	end
	return proj_dir
end

-- Detect OS for config dir
local uname = vim.loop.os_uname().sysname
local SYSTEM = "linux"
if uname == "Darwin" then
	SYSTEM = "mac"
elseif uname:match("Windows") then
	SYSTEM = "win"
end

-- Determine root_dir
local root_markers = { "pom.xml", "build.gradle", ".git", "mvnw", "gradlew" }
local root_dir = require("jdtls.setup").find_root(root_markers) or vim.fn.getcwd()

-- If running in Firenvim + Java, force fake Maven project
if vim.g.started_by_firenvim and vim.bo.filetype == "java" then
	local proj_dir = ensure_firenvim_project()
	root_dir = proj_dir
	local fake_file = proj_dir .. "/Firenvim.java"
	if vim.fn.filereadable(fake_file) == 0 then
		vim.fn.writefile({ "" }, fake_file)
	end
	vim.cmd("file " .. fake_file)
end

-- Paths
local home = vim.env.HOME
local mason = vim.fn.stdpath("data") .. "/mason"
local jdtls_path = mason .. "/packages/jdtls"
local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
local workspace_dir = home .. "/.local/share/jdtls-workspaces/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

-- Capabilities
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- JDTLS config
local config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xms1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher,
		"-configuration",
		jdtls_path .. "/config_" .. SYSTEM,
		"-data",
		workspace_dir,
	},
	root_dir = root_dir,
	capabilities = capabilities,
	settings = {
		java = {
			signatureHelp = { enabled = true },
			completion = { maxResults = 50 },
			sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
		},
	},
	init_options = { bundles = {} },
	on_attach = function(_, bufnr)
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end
		map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
		map("n", "gr", vim.lsp.buf.references, "References")
		map("n", "K", vim.lsp.buf.hover, "Hover")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("n", "<leader>oi", jdtls.organize_imports, "Organize Imports")
		map("n", "<leader>ev", jdtls.extract_variable, "Extract Variable")
		map("n", "<leader>em", jdtls.extract_method, "Extract Method")
	end,
}

jdtls.start_or_attach(config)
