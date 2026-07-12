# Athanor Public Receipt Tools

This directory contains the public verifier for the CV32E40P evidence packets.
It checks the packaged hashes, manifest policy, and public wording boundaries
without exposing candidate-generation prompts, orchestration, or private review
process.

Run from the repository root:

```bash
python3 athanor/verify_public_receipts.py
```

The verifier is intentionally lightweight. It does not rerun synthesis, static
timing, SAT, or simulation; each packet's `COMMANDS.md` gives the replay
commands for its local evidence.
