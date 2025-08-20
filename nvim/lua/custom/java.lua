local ok, jdtls = pcall(require, "jdtls")
if not ok then
	vim.notify("nvim-jdtls not installed", vim.log.levels.ERROR)
	return
end

-- Capabilities (autocomplete)
local capabilities = {}
local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
	capabilities = cmp.default_capabilities()
end

-- Detect OS
local system = "linux"
if vim.loop.os_uname().sysname == "Darwin" then
	system = "mac"
elseif vim.loop.os_uname().sysname:match("Windows") then
	system = "win"
end

-- Root dir (normal projects)
local root_markers = { "pom.xml", "build.gradle", ".git", "mvnw", "gradlew" }
local root_dir = require("jdtls.setup").find_root(root_markers)

if vim.g.started_by_firenvim then
	local proj_dir = vim.fn.expand("~/.local/share/firenvim-java")
	if vim.fn.isdirectory(proj_dir) == 0 then
		vim.fn.mkdir(proj_dir, "p")
		vim.fn.writefile({
			"<project>",
			"  <modelVersion>4.0.0</modelVersion>",
			"  <groupId>firenvim</groupId>",
			"  <artifactId>firenvim-project</artifactId>",
			"  <version>1.0.0</version>",
			"</project>",
		}, proj_dir .. "/pom.xml")
	end
	root_dir = proj_dir

	-- Force filetype
	if vim.bo.filetype ~= "java" then
		vim.bo.filetype = "java"
	end
end

-- Fallback if still nil
if not root_dir then
	root_dir = vim.fn.getcwd()
end

-- Paths
local mason = vim.fn.stdpath("data") .. "/mason"
local jdtls_path = mason .. "/packages/jdtls"
local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar", 1)
launcher = vim.split(launcher, "\n")[1]

-- Workspace
local workspace = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
if vim.fn.isdirectory(workspace) == 0 then
	vim.fn.mkdir(workspace, "p")
end

-- Config
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
		jdtls_path .. "/config_" .. system,
		"-data",
		workspace,
	},
	root_dir = root_dir,
	capabilities = capabilities,
}

jdtls.start_or_attach(config)
