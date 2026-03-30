# Roadmap

## ghcib

- **Reduce error verbosity** — currently ghcid output is included verbatim, which can flood agent context windows. Ideas:
  - Only include error title + location in status; allow querying full body on demand
  - Limit the number of errors returned unless explicitly requested

- **Tap into the ghci stream** — `Ghcid.startGhci` receives a load stream that is currently ignored (`\_ _ -> pure ()`); could be used for richer or more timely data

- **JSONL output format** — switch `ghcib status` output to JSONL to enable real-time streaming of status updates (possibly related to the ghci stream idea above)
