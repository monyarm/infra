______________________________________________________________________

## name: feedback-no-unasked-activation description: "Never run home-manager/nixos activation (switch, generation's activate script) without explicit user approval, even just to "verify" something." metadata: node_type: memory type: feedback originSessionId: f9ecc87f-b810-4e34-a029-29e13bc8db25

Never invoke a built generation's `activate` script (or `home-manager switch` /
`nixos-rebuild switch`) on your own initiative — not even to check that a new
`xdg.dataFile`/config landed, or to "just verify" something works.

**Why:** Activation is a real, live change to the user's actual system —
symlinks get swapped, systemd user services can restart, dotfiles get
overwritten. It is not equivalent to `nix build`, which only produces a store
path and touches nothing live. The user firmly rejected this (`BAD AI`) when
it was run mid-task just to populate a JSON file for a live audit.

**How to apply:** To inspect what an activation *would* produce, read files
straight out of the built store path (e.g.
`<generation>/home-files/.local/share/...`) instead of activating. If you
actually need the live environment updated (e.g. to run a script that reads
from `~/.local/share/...` at its real path), ask first and let the user run
`home-manager switch` themselves, or get explicit go-ahead before running it.
This is the same class of action as `git push`/`rm -rf`: build/eval freely,
but confirm before anything that mutates real system state.
