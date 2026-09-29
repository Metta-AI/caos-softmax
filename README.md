# caos-softmax

[caos](https://github.com/Metta-AI/caos) tools for Softmax's `coworld` and `softmax` CLIs, so an agent can upload policies and run hosted games from a caos session.

## `tools/gota`

Runs any `softmax` or `coworld` command in a caos worker (python 3.12, uv, network) with actions for the common Gods of the Arena workflow. Run `tool_help` on the imported path for parameters.

| action | what it does |
|---|---|
| `cli` | run `program` (`softmax` or `coworld`) with `args`; optional `filter` regex for huge output |
| `status` | `softmax status`: whose token is this |
| `upload` | `coworld upload-policy --file <file> --name <name>` |
| `play` | `coworld xp-request create <request>`, wait, print episode results |
| `results` | state and episode results of an existing xp-request |

There is deliberately no league-submit action: Softmax's guidance is to submit only after hosted games show a clear improvement and a human approves.

Results are cached by arguments; pass a changing `nonce` to re-poll.

### Use it

1. Import this repo into a caos session:
   `import_source(source="https://github.com/Metta-AI/caos-softmax.git", into="imports/caos-softmax")`
2. Give the session a Softmax token. A worker has no browser, so it authenticates with `softmax set-token`. In your **client repo** (the one whose `.caos-expr` pins caos), add `.caos-secrets/softmax-token`:

   ```
   name=softmax-token
   value:env=SOFTMAX_TOKEN
   entropy:env=CAOS_SOFTMAX_TOKEN_ENTROPY
   reader=imports/caos-softmax/tools/gota
   ```

   The secret lives in the client repo, not here, because caos matches a secret's `reader=` against the client's tree. Set `SOFTMAX_TOKEN` (from `uv run softmax login`, then `uv run softmax get-token`; it lasts about 24h) and `CAOS_SOFTMAX_TOKEN_ENTROPY` (any random 16+ char string, yours alone) in the environment, and start a new session.
3. `run_tool imports/caos-softmax/tools/gota action=status` to check.

Without a token the tool runs anonymously: public reads (`coworld leagues --json`) work, upload and play refuse with a clear message.

### Layout

The directory is a caos flake worker: `flake.nix` builds the image (python 3.12, uv, certs), `worker` is its `/worker`, and `.caos-expr` builds the image with caos' flake-builder and carries the tool's help text. Editing `worker` rebuilds the image. The `rev=` in `.caos-expr` must match the caos pin of the session that runs it.
