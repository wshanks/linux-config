local vim = vim

-- Set <space> as the leader key
-- See `:help mapleader`
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '

local Plug = vim.fn['plug#']

vim.call('plug#begin')
Plug('windwp/nvim-autopairs')
Plug('maxmx03/solarized.nvim')
Plug('junegunn/fzf')
Plug('junegunn/fzf.vim')
Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate'})
Plug('dense-analysis/ale')
Plug('nvim-lualine/lualine.nvim')
Plug('nvim-tree/nvim-web-devicons')  -- Wanted by lualine
Plug('lewis6991/gitsigns.nvim')
Plug('tpope/vim-fugitive')
Plug('christoomey/vim-tmux-navigator')
Plug('stevearc/aerial.nvim')
-- lsp/completion stuff
Plug('neovim/nvim-lspconfig')
Plug('hrsh7th/nvim-cmp')
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
vim.call('plug#end')

vim.o.colorcolumn = '80'
vim.o.number = true
-- Relative line numbers (see autocommands below)
-- vim.o.relativenumber = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true
-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 5
-- Show <tab> and trailing spaces
vim.o.list = true
vim.o.listchars = 'tab:▸\\ ,eol:¬'
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s) See `:help 'confirm'`
vim.o.confirm = true
-- Highlight the line where the cursor is on
-- vim.o.cursorline = true
-- Tab stuff
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 0
-- Tab completion for commands completes longest common match, then shows menu
-- of matches, then completes full matches.
vim.o.wildmode = 'longest,list,full'
-- Don't continue comments with o
vim.opt.formatoptions:remove("o")
vim.opt.formatoptions:append("r")

-- keymaps

-- [[ Set up keymaps ]] See `:h vim.keymap.set()`, `:h mapping`, `:h keycodes`
vim.keymap.set({ 'i' }, 'kj', '<Esc>')
vim.keymap.set({ 'i' }, '<c-s>', '<c-o>:update<CR>')
vim.keymap.set({ 'n' }, '<c-s>', ':update<CR>')
vim.keymap.set({ 'n' }, 'Q', ':qa!<CR>')
vim.keymap.set({ 'n' }, '<c-c>', ':pclose<CR>:lclose<CR>:cclose<CR>:helpclose<CR>')
-- Map <C-j>, <C-k>, <C-h>, <C-l> to navigate between windows in any modes
vim.keymap.set({ 't', 'i' }, '<C-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set({ 't', 'i' }, '<C-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set({ 't', 'i' }, '<C-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set({ 't', 'i' }, '<C-l>', '<C-\\><C-n><C-w>l')
vim.keymap.set({ 'n' }, '<C-h>', '<C-w>h')
vim.keymap.set({ 'n' }, '<C-j>', '<C-w>j')
vim.keymap.set({ 'n' }, '<C-k>', '<C-w>k')
vim.keymap.set({ 'n' }, '<C-l>', '<C-w>l')
-- Strip trailing whitespace
vim.keymap.set({ 'n' }, '<Leader>S', function()
    local save = vim.fn.winsaveview()
    vim.api.nvim_exec2('keepjumps keeppatterns silent! %s/\\s\\+$//e', {})
    vim.fn.winrestview(save)
end)

-- auto commands

-- Files marking the root of a project
local root_names = { '.git' }
local root_cache = {}

local set_root = function()
  -- Get directory path to start search from
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then return end
  path = vim.fs.dirname(path)

  local root = root_cache[path]
  if root == nil then
    local root_file = vim.fs.find(root_names, { path = path, upward = true })[1]
    if root_file == nil then
        -- autochdir when not in a project
        root = path
    else
        root = vim.fs.dirname(root_file)
    end
    root_cache[path] = root
  end

  -- Set current directory
  vim.fn.chdir(root)
end

local root_augroup = vim.api.nvim_create_augroup('MyAutoRoot', {})
vim.api.nvim_create_autocmd('BufEnter', { group = root_augroup, callback = set_root })

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Only relative line numbers while focused
vim.api.nvim_create_autocmd(
  { 'WinEnter', 'BufEnter', 'FocusGained' },
  { pattern = '*', command = 'set relativenumber' }
)
vim.api.nvim_create_autocmd(
  { 'WinLeave', 'BufLeave', 'FocusLost' },
  { pattern = '*', command = 'set norelativenumber' }
)

-- file types
vim.api.nvim_create_autocmd(
  { 'BufRead', 'BufNewFile' },
  { pattern = '*.j2', command = 'setfiletype jinja' }
)

-- Resize windows when terminal changes
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    vim.cmd("wincmd =")
  end,
})

-- Sync clipboard between OS and Neovim. Schedule the setting after `UiEnter` because it can
-- increase startup-time. Remove this option if you want your OS clipboard to remain independent.
-- See `:help 'clipboard'`
vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    vim.o.clipboard = 'unnamedplus'
  end,
})

-- Commands
local buff_completer = function(ArgLead, CmdLine, CursorPos)
  -- Completion function for all tokens in the current buffer

  -- Get all lines from the current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local words = {}
  local seen = {}
  -- Extract unique words
  for _, line in ipairs(lines) do
    for word in line:gmatch("%w+") do
      if not seen[word] then
        table.insert(words, word)
        seen[word] = true
      end
    end
  end
  -- Filter words that start with the current argument lead
  local matches = {}
  for _, word in ipairs(words) do
    if word:find("^" .. vim.pesc(ArgLead)) then
      table.insert(matches, word)
    end
  end
  return matches
end

-- plain (rip)grep results in quickfix
vim.o.grepprg = 'rg --column --line-number --no-heading --smart-case'
vim.api.nvim_create_user_command(
    'MyGrep',
    function(args)
        if args.args == '' then return end
        vim.cmd('silent! grep ' .. args.args)
        vim.cmd('botright copen')
        vim.fn.matchadd('Search', args.args)
    end,
    {
        ['nargs'] = '+',
        ['complete'] = buff_completer
    }
)
vim.keymap.set({ 'n' }, '<Leader>a', ':MyGrep ')


-- Plugin configuration
local ok
vim.o.termguicolors = true
vim.o.background = 'dark'
local solarized
ok, solarized = pcall(require, 'solarized')
if ok then
    solarized.setup({})
    vim.cmd.colorscheme 'solarized'
end

local autopairs
ok, autopairs = pcall(require, 'nvim-autopairs')
if ok then
    autopairs.setup()
end

local gitsigns
ok, gitsigns = pcall(require, 'gitsigns')
if ok then
    gitsigns.setup({
      on_attach = function(bufnr)
        gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({']c', bang = true})
          else
            gitsigns.nav_hunk('next')
          end
        end)

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({'[c', bang = true})
          else
            gitsigns.nav_hunk('prev')
          end
        end)

        -- Actions
        map('n', '<leader>hs', gitsigns.stage_hunk)
        map('n', '<leader>hr', gitsigns.reset_hunk)

        map('v', '<leader>hs', function()
          gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end)

        map('v', '<leader>hr', function()
          gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end)

        map('n', '<leader>hS', gitsigns.stage_buffer)
        map('n', '<leader>hR', gitsigns.reset_buffer)
        map('n', '<leader>hp', gitsigns.preview_hunk)
        map('n', '<leader>hi', gitsigns.preview_hunk_inline)

        map('n', '<leader>hb', function()
          gitsigns.blame_line({ full = true })
        end)

        map('n', '<leader>hd', gitsigns.diffthis)

        map('n', '<leader>hD', function()
          gitsigns.diffthis('~')
        end)

        map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
        map('n', '<leader>hq', gitsigns.setqflist)

        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
        map('n', '<leader>tw', gitsigns.toggle_word_diff)

        -- Text object
        map({'o', 'x'}, 'ih', gitsigns.select_hunk)

        -- Not copied from the readme:
        map('n', '<leader>gb', gitsigns.blame)
      end
    })
end

-- Aerial
local aerial
ok, aerial = pcall(require, "aerial")
if ok then
    aerial.setup({
      layout = { resize_to_content = false, width = 40 },
      on_attach = function(bufnr)
        -- Jump forwards/backwards with '{' and '}'
        vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
        vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
      end,
    })
    vim.keymap.set("n", "<leader>t", function()
        vim.cmd("AerialToggle")
        aerial.tree_close_all()
    end)
end

-- FZF config
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.exists(':GFiles') == 2 then
        -- Safe to use fzf.vim functions here
        vim.keymap.set({ 'n' }, '<Leader>f', function()
            local root_file = vim.fs.find({ '.git' }, { upward = true })[1]
            if root_file == nil then
                vim.api.nvim_exec2(":Files", {})
            else
                vim.api.nvim_exec2(":GFiles", {})
            end
        end)
        vim.keymap.set({ 'n' }, '<Leader>b', ':Buffers<CR>')
        vim.keymap.set({ 'n' }, '<Leader>A', ':Rg ')
        vim.g.fzf_vim = { }
        vim.g.fzf_preview_window = {'hidden,right,50%,<70(up,40%)', 'ctrl-f'}

        local fzf_grep = function(args)
            -- This is basically :Rg, just reimplemented so a different completer can
            -- be assigned
            local query = vim.fn['fzf#shellescape'](table.concat(args['fargs'], ' '))
            local grep_cmd = vim.o.grepprg .. ' --color=always -- ' .. query
            vim.fn['fzf#vim#grep'](grep_cmd,  vim.fn['fzf#vim#with_preview'](), args.bang)
        end
        vim.api.nvim_create_user_command(
            'FZFgrep',
            fzf_grep,
            {
                ['nargs'] = '*',
                ['bang'] = true,
                ['complete'] = buff_completer
            }
        )
        -- fzf#vim#grep(command, [spec dict], [fullscreen bool])
        vim.keymap.set({ 'n' }, '<Leader>A', ':FZFgrep ')
    end
  end
})

-- nvim-treesitter config
local nvimtreesitter
ok, nvimtreesitter = pcall(require, 'nvim-treesitter.configs')
if ok then
    nvimtreesitter.setup {
    -- one of "all", "language", or a list of languages
        ensure_installed = {
            "c", "bash", "json", "lua", "markdown", "python", "rust", "terraform",
            "yaml",
        },
        highlight = {
            enable = false,              -- false will disable the whole extension
            -- Python syntax looks worse with nvim-treesitter
            disable = { "python" },  -- list of language that will be disabled
        },
        fold = { enable = true },
        indent = { enable = true, disable = { 'yaml' }}
    }
end

-- ALE config
ok, _ = require('ale')
if ok then
    vim.g.ale_echo_msg_error_str = 'E'
    vim.g.ale_echo_msg_warning_str = 'W'
    vim.g.ale_echo_msg_format = '[%linter%] %s [%severity%]'
    vim.g.ale_fixers = {
        ["*"] = {"remove_trailing_lines", "trim_whitespace"},
        javascript = {"eslint"},
        python = {"ruff", "ruff_format"},
    }
    vim.keymap.set({ 'n' }, '<C-n>', '<Plug>(ale_next_wrap)')
    vim.keymap.set({ 'n' }, '<Leader>l', '<Plug>(ale_fix)')
end

-- lualine config
local lualine
ok, lualine = pcall(require, 'lualine')
if ok then
    lualine.setup()
end

-- Completion
local find_python = function()
    local python_path = vim.fn.exepath('python')

    local roots_found = vim.fs.find(
        { '.pixi', '.venv', '.tox' },
        { upward = true, type = 'directory', limit = 3 }
    )

    for _, root in ipairs(roots_found) do
        local root_name = vim.fs.basename(root)
        local py_candidate = ""
        if root_name == ".pixi" then
            py_candidate = vim.fs.joinpath(root, "envs/default/bin/python")
        elseif root_name == ".tox" then
            local tox_sub = ""
            local tox_subs = {}
            for name, _ in vim.fs.dir(root) do
                if name == "py" then
                    tox_sub = name
                    break
                elseif name:match('py%d+$') then
                    table.insert(tox_subs, name)
                end
            end
            if tox_sub ~= "" then
                py_candidate = vim.fs.joinpath(root, tox_sub, "bin/python")
            elseif next(tox_subs) ~= nil then
                table.sort(tox_subs)
                py_candidate = vim.fs.joinpath(root, tox_subs[#tox_subs], "bin/python")
            end
        else
            py_candidate = vim.fs.joinpath(root, "bin/python")
        end

        if py_candidate ~= "" and vim.uv.fs_stat(py_candidate) then
            python_path = py_candidate
            break
        end
    end

    return python_path
end
vim.api.nvim_create_user_command(
    'DebugPython',
    function()
        print(find_python())
    end,
    {
        ['nargs'] = 0
    }
)
local switch_pylsp = function()
    vim.lsp.config('pylsp', {
        settings = { pylsp = { plugins = { jedi = { environment = find_python()}}}}
    })
    vim.lsp.enable('pylsp', false)
    vim.lsp.enable('pylsp', true)
end
vim.api.nvim_create_user_command(
    'SwitchPyLSP',
    function()
        switch_pylsp()
    end,
    {
        ['nargs'] = 0
    }
)
-- Jump to different Python environment when switching between projects within
-- one editor session
--
-- Maybe we could call this automatically when switching buffers but just trying
-- out making it manual for now.
vim.keymap.set({ 'n' }, '<Leader>p', switch_pylsp)
local cmp
ok, cmp = pcall(require, 'cmp')
if ok then
    local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
    end

    cmp.setup({
        mapping = {
            ["<Tab>"] = cmp.mapping(
                function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif has_words_before() then
                        cmp.complete()
                    else
                        fallback()
                    end
                end,
                { "i", "s" }
            ),

            ["<S-Tab>"] = cmp.mapping(
                function()
                    if cmp.visible() then
                        cmp.select_prev_item()
                    end
                end,
                { "i", "s" }
            )
        },

        snippet = {
            expand = function(args)
                vim.snippet.expand(args.body)
            end
        },

        sources = cmp.config.sources(
            {
                { name = 'nvim_lsp' }
            },
            {
                { name = 'buffer' }
            },
            {
                -- TODO: I can't find any way to stop directory completions
                -- from getting a \/
                { name = 'path', option = { trailing_slash = false } }
            }
        )
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    vim.lsp.config('*', { capabilities = capabilities })
    vim.lsp.config('pylsp', {
        settings = {
            pylsp = {
                plugins = {
                    jedi = { environment = find_python()},
                    ruff = { enabled = true, formatEnabled = true }
                }
            }
        }
    })
    vim.lsp.enable('pylsp')
    vim.lsp.enable('luals')
end


-- Future:
--   * Learn more lsp functions / setup (C-], K, diagnostics?)
--   * Learn more about snippets
--   * Get lsp formatting working? Until then learn to use gw instead of gq
--   * telescope -- any value add over fzf?
--   * telescope-undo?
--   * completion -- try blink.cmp?
--   * Try to use the gitsigns mappings more (quick diff, blame, stage/unstage); check if fugitive is getting used any more
-- Todo: document setting nerd font in Ptyxis
