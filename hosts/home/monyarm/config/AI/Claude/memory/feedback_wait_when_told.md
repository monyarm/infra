______________________________________________________________________

## name: feedback-wait-when-told description: "When the user says "do X, tell me Y, and wait for me to confirm", stop all work after Y — don't move to other phases/tasks in the meantime." metadata: node_type: memory type: feedback originSessionId: 2f2a8057-2d8f-4802-8ae5-e17325ec1b10

When the user gives an instruction like "make the change, let me know what to set, and wait
for me to inform you I've done so", that means stop entirely after reporting back — not
"keep working on other independent phases while waiting."

**Why:** During the ScummVM games-registry work in `~/.nix`, the user asked for a GOG auth
change plus instructions, then explicit wait. Instead of pausing, work continued into an
unrelated phase (Steam/Alpha Polaris depot lookup), and in the process a self-introduced
Nix syntax error was left in `gog.nix` for a while before being caught — the user understandably
read this as "you broke gog.nix and didn't wait like I asked."

**How to apply:** Treat "wait for me" as a hard stop on ALL further edits/commands in that
turn and subsequent turns, even ones that seem independent or productive, until the user
responds. If there's truly independent, low-risk work the user would obviously want
continued, ask first rather than assuming — don't default to "keep busy."
