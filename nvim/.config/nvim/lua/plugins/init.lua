return {
  { "folke/neodev.nvim" },
  { "machakann/vim-sandwich" },
  { "neovim/nvim-lspconfig" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  { "simrat39/rust-tools.nvim" },
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
  },
  {
    'junegunn/fzf',
    event = "VeryLazy",
    build = function()
      vim.fn['fzf#install']()
    end
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        -- your config here
        disable_inline_completion = true,
      })
    end,
  },
  {
    "nvim-pack/nvim-spectre",
    build = false,
    lazy = true,
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
    keys = {
      { "<leader>fra", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
      { "<leader>frr", function() require("spectre").open_file_search({ select_word = true }) end, desc = "Replace in current word" },
    },
  },
  {
    "glepnir/lspsaga.nvim",
    branch = "main",
    config = function()
      require("lspsaga")
    end,
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
    }
  },
  { "stevearc/dressing.nvim",  event = "VeryLazy" },
  { "wakatime/vim-wakatime" },
  { "windwp/nvim-autopairs" }
}
