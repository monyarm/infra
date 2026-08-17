______________________________________________________________________

## name: feedback_answer_before_implementing description: "When a request is conditional ("assuming X, do Y"), answer/verify X first instead of jumping straight to building Y." metadata: node_type: memory type: feedback originSessionId: 2fc64ec9-bd87-4043-8d30-ca50e38538b0

When the user phrases a request as conditional on an assumption ("assuming X is true, can you add Y"), check/answer X directly first and report back — don't just go build Y.

**Why:** Asked to add a `--resume` flag to a cleanup script, conditioned on "assuming final-delete doesn't get overwritten early." Built the flag without first confirming that premise. Turned out confirming it would have mattered: the target file was only written at the very end of the phase the user was currently mid-way through, so nothing existed yet to resume from their specific interruption point — the feature was pointless for their actual situation. User: "You could have just told me there was an rm, and I would have told you not to add the feature cause it would have been pointless." Building first meant burning effort on something a direct answer would have avoided entirely.

**How to apply:** Spot the "assuming X" / "if X" framing in a request. Before implementing, check whether X actually holds (read the code, trace the logic, whatever's needed) and state the answer plainly. Only proceed to the actual ask once the premise is confirmed — or let the user redirect once they see it doesn't hold.
