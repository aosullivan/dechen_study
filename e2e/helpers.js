const { expect } = require('@playwright/test');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function labelPattern(label) {
  return new RegExp(escapeRegex(label), 'i');
}

function roleButton(page, label) {
  return page.getByRole('button', { name: labelPattern(label) }).first();
}

async function passAccessibilityGateIfPresent(page) {
  const labels = ['Enable accessibility', 'Enable Accessibility'];
  const cssGate = page.locator(
    'flt-semantics-placeholder[aria-label*="Enable accessibility" i]',
  );

  if ((await cssGate.count()) > 0) {
    const gate = cssGate.first();
    await gate.evaluate((el) => {
      const s = el.style;
      s.position = 'fixed';
      s.left = '16px';
      s.top = '16px';
      s.width = '240px';
      s.height = '80px';
      s.opacity = '1';
      s.zIndex = '2147483647';
      s.pointerEvents = 'auto';
    });
    try {
      await gate.click({ force: true, timeout: 2000 });
    } catch (_) {
      await gate.evaluate((el) => {
        el.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }));
        el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        el.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
        el.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }));
        el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        if (typeof el.click === 'function') el.click();
      });
    }
    await page.waitForTimeout(1200);
    if ((await cssGate.count()) === 0) return true;
  }

  for (const frame of page.frames()) {
    for (const label of labels) {
      const gateButton = frame.getByRole('button', { name: label });
      if ((await gateButton.count()) > 0) {
        await gateButton.first().evaluate((el) => {
          el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
          if (typeof el.click === 'function') el.click();
        });
        await page.waitForTimeout(1200);
        return true;
      }
    }
  }

  return false;
}

async function waitForLocatorWithGate(page, locator, timeoutMs = 60_000) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    try {
      if ((await locator.count()) > 0 && (await locator.first().isVisible())) {
        return;
      }
    } catch (_) {
      // Keep polling through transient render states.
    }

    await passAccessibilityGateIfPresent(page);
    await page.waitForTimeout(1500);
  }

  await expect(locator.first()).toBeVisible({ timeout: 5_000 });
}

async function openTextOptions(page, appPath, appTitle) {
  await page.goto(appPath, { waitUntil: 'domcontentloaded' });
  await waitForLocatorWithGate(
    page,
    page.getByRole('heading', { name: labelPattern(appTitle) }),
  );
  const anyModeButton = page.getByRole('button', {
    name: /Daily Verses|Guess the Chapter|Quiz|Read|Textual Structure/i,
  });
  await waitForLocatorWithGate(page, anyModeButton);
}

async function openMode(page, appPath, appTitle, modeLabel) {
  await openTextOptions(page, appPath, appTitle);
  const modeBtn = roleButton(page, modeLabel);
  await expect(modeBtn).toBeVisible();
  try {
    await modeBtn.click();
  } catch (_) {
    await modeBtn.click({ force: true });
  }
  await page.waitForTimeout(700);

  try {
    await modeBtn.evaluate((el) => {
      el.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }));
      el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
      el.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
      el.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }));
      el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      if (typeof el.click === 'function') el.click();
    });
  } catch (_) {
    // Ignore stale element on successful navigation.
  }
  await page.waitForTimeout(500);
}

async function enterModeWithRetries(
  page,
  { appPath, appTitle, modeLabel, isEntered, attempts = 4 },
) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    await openMode(page, appPath, appTitle, modeLabel);
    try {
      if (await isEntered()) return;
    } catch (_) {
      // retry
    }
    await page.waitForTimeout(600);
  }
  throw new Error(`Failed to enter mode "${modeLabel}" for ${appTitle}`);
}

async function openRead(page, appPath, appTitle) {
  await openMode(page, appPath, appTitle, 'Read');

  // Multi-chapter texts show a chapter picker first.
  const chapterOneButton = page
    .getByRole('button', { name: /^1\./ })
    .first();
  if ((await chapterOneButton.count()) > 0) {
    await chapterOneButton.click();
  }

  await page.waitForTimeout(500);
  await expect(firstVerseRefLocator(page)).toBeVisible();
}

function firstVerseRefLocator(page) {
  return page.getByText(/Verse\s+\d+(?:\.\d+)?/i).first();
}

async function firstVerseRefText(page) {
  const text = (await firstVerseRefLocator(page).innerText()).trim();
  const match = text.match(/Verse\s+(\d+)(?:\.(\d+))?/i);
  if (!match) {
    throw new Error(`Unable to parse verse ref from "${text}"`);
  }
  const chapter = Number.parseInt(match[1], 10);
  const verse = match[2] ? Number.parseInt(match[2], 10) : 0;
  return { label: text, chapter, verse };
}

function assertOrderedVerseSteps(steps, maxVerseStep = 1) {
  for (let i = 1; i < steps.length; i += 1) {
    const prev = steps[i - 1];
    const next = steps[i];

    if (next.chapter < prev.chapter) {
      throw new Error(
        `Reader moved backwards in chapter: ${prev.label} -> ${next.label}`,
      );
    }

    if (next.chapter === prev.chapter) {
      const delta = next.verse - prev.verse;
      if (delta < 0) {
        throw new Error(
          `Reader moved backwards in verse: ${prev.label} -> ${next.label}`,
        );
      }
      if (delta > maxVerseStep) {
        throw new Error(
          `Reader skipped verses: ${prev.label} -> ${next.label} (delta ${delta})`,
        );
      }
    }
  }
}

module.exports = {
  roleButton,
  labelPattern,
  passAccessibilityGateIfPresent,
  waitForLocatorWithGate,
  enterModeWithRetries,
  openTextOptions,
  openMode,
  openRead,
  firstVerseRefText,
  assertOrderedVerseSteps,
};
