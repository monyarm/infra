______________________________________________________________________

## name: feedback_no_shell_history_snooping description: "Never grep the user's shell history to recover lost context; ask them directly instead." metadata: node_type: memory type: feedback originSessionId: 2fc64ec9-bd87-4043-8d30-ca50e38538b0

Don't search `~/.zsh_history`, `~/.bash_history`, or similar to reconstruct details from earlier in a conversation (e.g. an exact command/snippet structure that got summarized out of context).

**Why:** User reacted sharply ("why are you checking the zsh history? bad ai") — it reads as snooping through their personal activity rather than a legitimate debugging step, even when the intent was just to recover a forgotten snippet's shape.

**How to apply:** When earlier context (a snippet, a JSON structure, a command's exact form) isn't available anymore, ask the user directly rather than trying to reconstruct it by searching their history files, browser history, or similar personal logs.
