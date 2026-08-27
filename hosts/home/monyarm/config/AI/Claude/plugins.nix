{ fetchGitTree, sources, ... }:
{
  programs.claude-code.plugins = {
    # official plugin, previously installed via the marketplace -- now a plain fetch
    claude-code-setup =
      fetchGitTree sources.claude.plugins.claude-plugins-official + "/plugins/claude-code-setup";

    # jetbrains benchmark: claimed -54% code/-22% tokens; measured -15% code/-10.3% cost
    # https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/
    ponytail = fetchGitTree sources.claude.plugins.ponytail;

    # jetbrains benchmark: claimed -65% tokens; measured -8.5% on agentic tasks
    # https://blog.jetbrains.com/ai/2026/07/speak-to-ai-agents-like-cavemen-tosave-tokens/
    caveman = fetchGitTree sources.claude.plugins.caveman;

    # skills lib: TDD, debugging, planning (/brainstorm, /write-plan, /execute-plan)
    superpowers = fetchGitTree sources.claude.plugins.superpowers;

  };

  # rtk (Rust Token Killer) -- NOT installed. JetBrains benchmark: 7.6% cost INCREASE at
  # low reasoning effort despite rtk's own dashboard claiming 60-90% savings.
  # https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/
}
