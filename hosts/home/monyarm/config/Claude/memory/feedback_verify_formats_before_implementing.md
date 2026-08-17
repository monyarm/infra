______________________________________________________________________

## name: feedback-verify-formats-before-implementing description: "Research and verify real-world file formats/conventions (binary formats, CDN URL schemes, third-party tool behavior) before writing serialization code, rather than assuming." metadata: node_type: memory type: feedback originSessionId: 0e784c34-885f-4e4e-b82a-0a308b62f728

When implementing something that touches an external, real-world format or convention (a binary file format, a third-party CDN's URL scheme, another program's on-disk layout), do the research/verification first rather than assuming or pattern-matching from a superficially similar case.

Concrete instance: while planning real Steam `shortcuts.vdf` + `appmanifest.acf` generation, I initially conflated the two as needing one shared serializer. The user caught this: "I'm pretty sure acf and vdf are separate formats, or at least shortcuts.vdf is? I'd like you to look things up before deciding how to write the acf files." Research confirmed they are indeed different: `shortcuts.vdf` is Valve's **binary** type-tagged KeyValues encoding, while `.acf` files use the **plain-text** KeyValues format. Building two separate, correctly-modeled writers (verified via web research, then further verified against a real independent Python `vdf` parser round-trip and manual hex-dump inspection) caught this before it became a real bug.

**Why:** this is a personal Nix config where correctness of these integrations directly affects whether Steam actually recognizes files at runtime — getting a format wrong isn't caught by `nix eval`, only by real-world testing, so upfront research is cheaper than a broken artifact discovered later.

**How to apply:** when a task involves generating output that must interoperate with an external, already-fixed format/API/convention (not something this repo defines itself), use WebSearch/WebFetch to confirm the exact format before writing the implementation, and where feasible validate the output against an independent real-world parser/tool (not just eval-success) before considering it done.
