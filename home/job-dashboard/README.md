# Job dashboard

`jobs.qgroget.com` is implemented here, not in an external application repository.
`home/hermes.nix` installs `server.py` and `index.html` into
`/home/hermes/job-dashboard` and runs the Python stdlib HTTP service on loopback
port 3003. Traefik exposes it as a private (mTLS) route.

## Triage

Use **Sélectionner pour le triage** on an **À postuler** card to move only that
application into **Triage**. From there, **Remettre à postuler** undoes the selection,
and **Marquer postulé** advances it. The edit dialog also exposes the new status.
This is a mutually exclusive Kanban status (`triage`), not a duplicate application
or a change to its match score. Existing records stay in their current columns;
no data migration is needed. Status and metadata use the existing JSON persistence.

## Tests (no production data)

From the repository root:

```sh
python3 -m unittest discover -s home/job-dashboard -v
npm install --prefix "$TMPDIR/job-dashboard-tests" playwright@1.65.0
"$TMPDIR/job-dashboard-tests/node_modules/.bin/playwright" install chromium
NODE_PATH="$TMPDIR/job-dashboard-tests/node_modules" node home/job-dashboard/test_browser.cjs
```

If the default Playwright browser cache is read-only, export
`PLAYWRIGHT_BROWSERS_PATH="$TMPDIR/job-dashboard-browsers"` before installation and
execution. On Linux, browser libraries may require `playwright install --with-deps chromium`.
The browser test starts its own loopback server on an ephemeral port and cleans
up its temporary JSON file. CI runs both HTTP and Chromium tests.

Merging or running tests does not authorize production activation. Apply changes
through the existing Home Manager deployment only after explicit approval.
