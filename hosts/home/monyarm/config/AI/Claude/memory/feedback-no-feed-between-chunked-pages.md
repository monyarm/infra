---
name: feedback-no-feed-between-chunked-pages
description: When splitting long output into printer pages, reset the buffer (ESC @) between chunks instead of feeding; the user rejected inter-page feeds as wrong for long single documents
metadata:
  type: feedback
  origin: opencode
  modified: 2026-11-16T21:26:03.548Z
---

Chunking long print output must not insert a paper feed between chunks. Non-final chunks should end with a buffer reset (`ESC @`), which clears the full print buffer without moving the paper; only the final chunk emits the normal trailing feed. The stdin/streaming path must behave the same.

**Why:** the user called the inter-page feed "dumb, cause what if we feed it a long single page document?" — a document that is one continuous page must print continuously with a single feed at the end, not as visibly separate sheets.

**How to apply:** when page size forces splitting (on this printer the firmware stops draining the link once its buffer fills), keep the split invisible: buffer reset between pages, one feed at the very end. Also, the user expects a discriminating hardware test ("test before implementing") before committing to a chunking mechanism rather than guessing and shipping it.
