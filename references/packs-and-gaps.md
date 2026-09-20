# The packs, and the gaps they leave

Peter has `superpowers`, `karpathy-skills`, `ccl-skills`, `ui-ux-pro-max` and
others installed. **Two of the rules above already exist there, and I violated
them anyway.** That is the honest starting point:

| Existing skill | Says | Why I still failed |
| --- | --- | --- |
| `superpowers:verification-before-completion` | "no completion claims without fresh verification evidence" | I *did* run every command I had. **Its gap: it assumes a command exists that proves the claim.** For a render bug in a node-only repo, none does — so the iron law was satisfied and the bug shipped anyway |
| `karpathy-guidelines` §1 | "Don't assume. If uncertain, ask." | Generic. **Gap: it does not name the trigger that fires most** — a search that misses being read as proof of absence |
| `superpowers:systematic-debugging` | root cause before fixes | Good, and it scopes to *one* bug. **Gap: nothing tells me to enumerate the whole class** the reported bug belongs to |

So the rules here are deliberately narrower than the packs': they name the
**specific** trigger, in the **specific** repo, with the evidence of what
happened when it was missed. A general principle I already agreed with did not
stop me; a concrete trigger has a chance.

**Use the packs.** `verification-before-completion` before any completion claim,
`systematic-debugging` on any bug, `andrej-karpathy-skills:karpathy-guidelines`
while writing. This
skill adds what they cannot know: which criterion has no command, which repo
hides its design file, and which two surfaces must both be checked.
