# Configuration

Whether you use the Home Manager module or the package override, you can customize your NvChad experience by passing extra configurations, plugins, and packages. 

When using Home Manager, these are set under `programs.nvchad.<option>`. When using the standalone package, they are passed as arguments to the `.override { ... }` function.

## Available Options

Below is a comprehensive list of available options grouped by their purpose. 

> [!NOTE]
> Options marked with **(HM)** in their description (`enable`, `hm-activation`, `backup`) are only applicable when using the Home Manager module. They have no effect when using the standalone package `.override`.

---

### Core & Environment

This section covers options that affect the underlying Neovim executable and the tools available in its environment.

#### `neovim`
**Type:** `package`  
**Default:** `pkgs.neovim`

The Neovim package to use under the NvChad wrapper. You can use this to switch to a nightly build or a custom-compiled version of Neovim.

**Example (Home Manager):**
```nix
programs.nvchad.neovim = pkgs.neovim-unwrapped;
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  neovim = pkgs.neovim-unwrapped;
};
```

#### `extraPackages`
**Type:** `list of packages`  
**Default:** `[ ]` (plus default starter dependencies)

A list of additional packages (like LSPs, formatters, linters) to make available to NvChad as runtime dependencies. 

> [!TIP]
> Keep your global environment clean! Add tools like LSPs (e.g., `pyright`, `nil`, `gopls`) here. They will only be available within the NvChad environment, ensuring your editor finds them without polluting your system.

**Example (Home Manager):**
```nix
programs.nvchad.extraPackages = with pkgs; [
  ripgrep
  lua-language-server
  stylua
  nodePackages.bash-language-server
];
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  extraPackages = with pkgs; [
    ripgrep
    lua-language-server
    stylua
    nodePackages.bash-language-server
  ];
};
```

#### `gcc`
**Type:** `package`  
**Default:** `pkgs.gcc`

The GCC compiler you want to use. Tree-sitter relies heavily on a C compiler to build parsers. You can override this if you need a specific compiler toolchain.

**Example (Home Manager):**
```nix
programs.nvchad.gcc = pkgs.gcc13;
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  gcc = pkgs.gcc13;
};
```

---

### Customization & Plugins

This section covers options for injecting custom Lua code, modifying the UI, and managing plugins.

#### `extraConfig`
**Type:** `string`  
**Default:** `""`

Arbitrary Lua code that will be loaded *after* NvChad is fully loaded. Use this to set custom `vim.opt` settings, keymaps, or auto-commands.

> [!CAUTION]
> If you have a very complex configuration, writing massive multiline strings in Nix can become hard to maintain. Consider splitting them out into separate `.lua` files and reading them with `builtins.readFile`.

**Example (Home Manager):**
```nix
programs.nvchad.extraConfig = ''
  -- Custom vim options
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.expandtab = true
  
  -- Custom keymaps
  vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
'';
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  extraConfig = ''
    -- Custom vim options
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.expandtab = true
    
    -- Custom keymaps
    vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
  '';
};
```

#### `chadrcConfig`
**Type:** `string`  
**Default:** `""`

Configuration that replaces `chadrc.lua`. This is primarily used to override the default UI configuration (themes, transparency, etc.). 

> [!IMPORTANT]
> Make sure to include `local M = {}` at the top, and `return M` at the bottom of your string.

**Example (Home Manager):**
```nix
programs.nvchad.chadrcConfig = ''
  local M = {}
  M.ui = {
    theme = "catppuccin",
    transparency = true,
  }
  return M
'';
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  chadrcConfig = ''
    local M = {}
    M.ui = {
      theme = "catppuccin",
      transparency = true,
    }
    return M
  '';
};
```

#### `extraPlugins`
**Type:** `string` (Lua code)  
**Default:** `""`

A string containing a Lua table of extra plugins you want to install. This list will be loaded and managed by `lazy.nvim`.

**Example (Home Manager):**
```nix
programs.nvchad.extraPlugins = ''
  return {
    { "equalsraf/neovim-gui-shim", lazy = false },
    { "nvim-lua/plenary.nvim" },
    {
      "xeluxee/competitest.nvim",
      dependencies = "MunifTanjim/nui.nvim",
      config = function() require("competitest").setup() end,
    },
  }
'';
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  extraPlugins = ''
    return {
      { "equalsraf/neovim-gui-shim", lazy = false },
      { "nvim-lua/plenary.nvim" },
      {
        "xeluxee/competitest.nvim",
        dependencies = "MunifTanjim/nui.nvim",
        config = function() require("competitest").setup() end,
      },
    }
  '';
};
```

#### `lazy-lock`
**Type:** `string` (JSON content)  
**Default:** `""`

The contents of a `lazy-lock.json` file. If provided, this will lock `lazy.nvim`'s plugin versions to ensure reproducible plugin installations. Leave it empty if you want `lazy.nvim` to manage the lockfile dynamically in your home directory.

**Example (Home Manager):**
```nix
programs.nvchad.lazy-lock = builtins.readFile ./lazy-lock.json;
```

**Example (Standalone):**
```nix
nvchad = inputs.nix4nvchad.packages.${system}.default.override {
  lazy-lock = builtins.readFile ./lazy-lock.json;
};
```

---

### Home Manager Specifics

These options dictate how the Home Manager module behaves when activating the configuration.

#### `enable`
**Type:** `boolean`  
**Default:** `false`

**(HM)** Enables the NvChad Home Manager module. If set to `false`, the module is ignored when building the new generation.

**Example:**
```nix
programs.nvchad.enable = true;
```

#### `hm-activation`
**Type:** `boolean`  
**Default:** `true`

**(HM)** If set to `false`, Home Manager will **not** automatically copy the NvChad configuration to `~/.config/nvim`. This allows you to manage the configuration directory manually (e.g., by cloning the NvChad repository yourself) while still using the wrapped executable and isolated dependencies provided by this module.

**Example:**
```nix
programs.nvchad.hm-activation = false;
```

#### `backup`
**Type:** `boolean`  
**Default:** `true`

**(HM)** Because this module copies NvChad to `~/.config/nvim` instead of creating a read-only symlink (a necessary workaround for NvChad's lazy-loading), it will create a backup of your existing configuration at `~/.config/nvim_%Y_%m_%d_%H_%M_%S.bak` during generation switches. 

If you do not want backups to be created, disable this option.

**Example:**
```nix
programs.nvchad.backup = false;
```