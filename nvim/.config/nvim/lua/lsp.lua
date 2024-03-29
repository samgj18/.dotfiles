local api = vim.api
local map = vim.keymap.set

local setup = function()
  require("neodev").setup({
    -- add any options here, or leave empty to use the default settings
  })
  local lsp_config = require("lspconfig")
  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  lsp_config.util.default_config = vim.tbl_extend("force", lsp_config.util.default_config, {
    capabilities = capabilities,
  })

  require("fidget").setup({
    -- add any options here, or leave empty to use the default settings
  })

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })

  local lsp_group = api.nvim_create_augroup("lsp", { clear = true })

  local on_attach = function(client, bufnr)
    -- LSP agnostic mappings
    map("n", "gd", vim.lsp.buf.definition)
    map("n", "gtd", vim.lsp.buf.type_definition)
    map("n", "K", vim.lsp.buf.hover)
    map("n", "gi", vim.lsp.buf.implementation)
    map("n", "gr", vim.lsp.buf.references)
    map("n", "<leader>sh", vim.lsp.buf.signature_help)
    map("n", "<leader>rn", vim.lsp.buf.rename)
    map("n", "<leader>ca", vim.lsp.buf.code_action)
    map("n", "<leader>cl", vim.lsp.codelens.run)

    map("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end)

    api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
  end

  --================================
  -- Metals specific setup
  --================================
  local metals_config = require("metals").bare_config()
  metals_config.tvp = {
    icons = {
      enabled = true,
    },
  }


  local function metals_status_handler(err, status, ctx)
    local val = {}
    -- trim and remove spinner
    local text = status.text:gsub('[⠇⠋⠙⠸⠴⠦]', ''):gsub("^%s*(.-)%s*$", "%1")
    if status.hide then
      val = { kind = "end" }
    elseif status.show then
      val = { kind = "begin", title = text }
    elseif status.text then
      val = { kind = "report", message = text }
    else
      return
    end
    local msg = { token = "metals", value = val }
    vim.lsp.handlers["$/progress"](err, msg, ctx)
  end

  metals_config.handlers = { ['metals/status'] = metals_status_handler }

  metals_config.settings = {
    showImplicitArguments = true,
    showImplicitConversionsAndClasses = true,
    showInferredType = true,
    serverVersion = "latest.snapshot",
  }

  metals_config.init_options.statusBarProvider = "on"
  metals_config.capabilities = capabilities

  metals_config.on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    map("v", "KA", require("metals").type_of_range)

    map("n", "<leader>ws", function()
      require("metals").hover_worksheet({ border = "single" })
    end)

    map("n", "<leader>tt", require("metals.tvp").toggle_tree_view)

    map("n", "<leader>tr", require("metals.tvp").reveal_in_tree)

    map("n", "<leader>mmc", require("metals").commands)

    map("n", "<leader>mts", function()
      require("metals").toggle_setting("showImplicitArguments")
    end)

    api.nvim_create_autocmd("CursorHold", {
      callback = vim.lsp.buf.document_highlight,
      buffer = bufnr,
      group = lsp_group,
    })
    api.nvim_create_autocmd("CursorMoved", {
      callback = vim.lsp.buf.clear_references,
      buffer = bufnr,
      group = lsp_group,
    })
    api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      callback = vim.lsp.codelens.refresh,
      buffer = bufnr,
      group = lsp_group,
    })
    api.nvim_create_autocmd("FileType", {
      pattern = { "dap-repl" },
      callback = function()
        require("dap.ext.autocompl").attach()
      end,
      group = lsp_group,
    })

    local dap = require("dap")

    dap.configurations.scala = {
      {
        type = "scala",
        request = "launch",
        name = "Run or test with input",
        metals = {
          runType = "runOrTestFile",
          args = function()
            local args_string = vim.fn.input("Arguments: ")
            return vim.split(args_string, " +")
          end,
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Run or Test",
        metals = {
          runType = "runOrTestFile",
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Test Target",
        metals = {
          runType = "testTarget",
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Run minimal2 main",
        metals = {
          mainClass = "minimal2.Main",
          buildTarget = "minimal",
        },
      },
    }

    map("n", "<leader>dc", require("dap").continue)
    map("n", "<leader>dr", require("dap").repl.toggle)
    map("n", "<leader>dK", require("dap.ui.widgets").hover)
    map("n", "<leader>dt", function()
      require("dap").toggle_breakpoint('x == 6')
    end)
    map("n", "<leader>dso", require("dap").step_over)
    map("n", "<leader>dsi", require("dap").step_into)
    map("n", "<leader>drl", require("dap").run_last)

    dap.listeners.after["event_terminated"]["nvim-metals"] = function(session, body)
      --vim.notify("Tests have finished!")
      dap.repl.open()
    end

    require("metals").setup_dap()
  end

  local nvim_metals_group = api.nvim_create_augroup("nvim-metals", { clear = true })
  api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt", "java" },
    callback = function()
      require("metals").initialize_or_attach(metals_config)
    end,
    group = nvim_metals_group,
  })

  local rust_tools_opts = {
    tools = {
      hover_with_actions = false,
      reload_workspace_from_cargo_toml = true,
      inlay_hints = {
        only_current_line = false,
        show_parameter_hints = true,
        parameter_hints_prefix = " <- ",
        other_hints_prefix = "=> ",
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = "Comment",
      },
    },
    server = {
      on_attach = on_attach,
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = {
            command = "clippy",
          },
        },
      },
    },
  }

  require("rust-tools").setup(rust_tools_opts)

  -- For editing tree-sitter grammars
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "grammar.js", "corpus/*.txt" },
    callback = function()
      vim.cmd("setfiletype tree-sitter-grammar")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    pattern = { "grammar.js" },
    command = "set syntax=javascript",
  })

  lsp_config.lua_ls.setup({
    on_attach = on_attach,
    commands = {
      Format = {
        function()
          require("stylua-nvim").format_file()
        end,
      },
    },
    settings = {
      Lua = {
        diagnostics = { globals = { "vim", "it", "describe", "before_each" } },
        telemetry = { enable = false },
      },
    },
  })

  lsp_config.jsonls.setup({
    on_attach = on_attach,
    commands = {
      Format = {
        function()
          vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
        end,
      },
    },
  })

  lsp_config.yamlls.setup({
    on_attach = on_attach,
    settings = {
      yaml = {
        schemas = {
          ["https://raw.githubusercontent.com/oyvindberg/bleep/master/schema.json"] = "bleep.yaml",
        },
      },
    },
  })

  lsp_config.smithy_ls.setup({
    on_attach = on_attach,
    cmd = { "cs", "launch", "com.disneystreaming.smithy:smithy-language-server:0.0.21", "--", "0" },
  })

  -- These server just use the vanilla setup
  local servers = { "bashls", "dockerls", "html", "tsserver", "gopls", "clangd" }
  for _, server in pairs(servers) do
    lsp_config[server].setup({ on_attach = on_attach })
  end
end

return {
  setup = setup,
}
