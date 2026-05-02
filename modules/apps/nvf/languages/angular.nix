{pkgs, ...}: {
  vim = {
    languages = {
      typescript.enable = true;
      html.enable = true;
      css.enable = true;
    };
    lsp.presets.tailwindcss-language-server.enable = true;
  };
}
