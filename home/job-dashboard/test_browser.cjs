// Run with Node and Playwright on NODE_PATH; never connects to production.
const { chromium } = require('playwright');
const { spawn } = require('node:child_process');
const { mkdtempSync, rmSync, readFileSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const assert = require('node:assert/strict');

(async () => {
  const directory = mkdtempSync(join(tmpdir(), 'jobs-triage-'));
  const child = spawn('python3', ['-u', '-c', `
import server
server.DATA_FILE = ${JSON.stringify(join(directory, 'data.json'))}
httpd = server.ThreadingHTTPServer(('127.0.0.1', 0), server.Handler)
print(httpd.server_port, flush=True)
httpd.serve_forever()
`], { cwd: __dirname, stdio: ['ignore', 'pipe', 'inherit'] });
  let browser;
  try {
    const port = await new Promise((resolve, reject) => {
      let text = '';
      child.stdout.on('data', data => {
        text += data;
        if (text.includes('\n')) resolve(Number(text.trim()));
      });
      child.on('error', reject);
      child.on('exit', code => reject(new Error(`Server exited: ${code}`)));
    });
    const base = `http://127.0.0.1:${port}`;
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    for (const company of ['Selected', 'Unselected']) {
      const response = await page.request.post(base + '/api/jobs', {
        data: { company, title: 'Rust intern', notes: 'Keep notes', url: 'https://example.com' },
      });
      assert.equal(response.status(), 201);
    }
    await page.goto(base);
    const column = status => page.locator(`.col[data-status="${status}"]`);
    const count = async (status, expected) => {
      await page.waitForFunction(({status, expected}) =>
        document.querySelector(`.col[data-status="${status}"] .count`)?.textContent === String(expected),
        { status, expected });
      assert.equal(await column(status).locator('.card').count(), expected);
    };
    await count('backlog', 2);
    assert.equal(await page.locator('.col').count(), 6);
    await column('backlog').locator('.card').filter({ hasText: /^Selected\b/ })
      .getByRole('button', { name: 'Sélectionner pour le triage', exact: true }).click();
    await count('triage', 1);
    await count('backlog', 1);
    assert.equal(await page.locator('#modal').evaluate(el => el.classList.contains('open')), false);
    await page.waitForFunction(() => document.querySelector('#stats').textContent.includes('Triage 1'));
    await page.reload();
    await count('triage', 1);
    const disk = JSON.parse(readFileSync(join(directory, 'data.json'))).jobs;
    assert.equal(disk.find(job => job.company === 'Selected').status, 'triage');
    assert.equal(disk.find(job => job.company === 'Unselected').status, 'backlog');
    await page.getByRole('button', { name: 'Tri :' }).click();
    await count('triage', 1);
    await column('triage').locator('.card .c').click();
    assert.equal(await page.locator('#f_status').inputValue(), 'triage');
    assert.equal(await page.locator('#f_notes').inputValue(), 'Keep notes');
    await page.locator('#f_notes').fill('Edited from triage');
    await page.getByRole('button', { name: 'Enregistrer', exact: true }).click();
    await page.waitForFunction(() => !document.querySelector('#modal').classList.contains('open'));
    await count('triage', 1);
    await column('triage').getByRole('button', { name: 'Remettre à postuler', exact: true }).click();
    await count('triage', 0);
    await count('backlog', 2);
    await column('backlog').locator('.card').filter({ hasText: /^Selected\b/ })
      .getByRole('button', { name: 'Sélectionner pour le triage', exact: true }).click();
    await count('triage', 1);
    await column('triage').getByRole('button', { name: 'Marquer postulé', exact: true }).click();
    await count('triage', 0);
    await count('applied', 1);
    assert.equal(await column('applied').locator('.card').count(), 1);
    // Dragging a card to any column persists the new status.
    await column('applied').locator('.card').dragTo(column('interview'));
    await count('applied', 0);
    await count('interview', 1);
    await page.reload();
    await count('interview', 1);

    // Network failure leaves the card in place, reports the error and enables retry.
    await page.route('**/api/jobs/*', route => route.abort());
    const dialog = page.waitForEvent('dialog');
    const click = column('backlog').getByRole('button', { name: 'Sélectionner pour le triage', exact: true }).click();
    const alert = await dialog;
    assert.match(alert.message(), /Impossible de déplacer/);
    await alert.accept();
    await click;
    await count('backlog', 1);
    assert.equal(await column('backlog').getByRole('button').isEnabled(), true);
    await page.unroute('**/api/jobs/*');

    for (const [width, expectedColumns] of [[1440, 6], [900, 2], [390, 1]]) {
      await page.setViewportSize({ width, height: 1000 });
      const layout = await page.locator('#kanban').evaluate(el => ({
        columns: getComputedStyle(el).gridTemplateColumns.split(' ').length,
        overflow: document.documentElement.scrollWidth > innerWidth,
      }));
      assert.equal(layout.columns, expectedColumns);
      assert.equal(layout.overflow, false);
    }
    assert.deepEqual(errors, []);
    console.log('PASS: selection, persistence/reload, counters, sorting, edit, return, apply, network error and responsive layouts (1440/900/390px)');
  } finally {
    if (browser) await browser.close();
    child.kill();
    await new Promise(resolve => child.exitCode !== null ? resolve() : child.once('exit', resolve));
    rmSync(directory, { recursive: true, force: true });
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
