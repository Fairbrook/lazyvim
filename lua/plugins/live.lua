return {
  {
    "azratul/live-share.nvim",
    dependencies = {
      "jbyuki/instant.nvim",
    },
    config = function()
      require("live-share.provider").register("live-share-socat", {
        command = function(_cfg, port, service_url)
          return string.format("live-share-socat %d %d > %s", port, port, service_url)
        end,
        pattern = "%d+.%d+.%d+.%d+ %d+",
      })
      vim.g.instant_username = "kevinm"
      require("live-share").setup({
        service = "live-share-socat",
      })
    end,
  },
}
