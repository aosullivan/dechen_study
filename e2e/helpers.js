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

function modeButton(page, label) {
  return page
    .getByRole('button', {
      name: new RegExp(`^\\s*${escapeRegex(label)}\\s*$`, 'i'),
    })
    .first();
}

async function hasSemanticsEnabled(page) {
  const buttons = page.getByRole('button');
  return (await buttons.count()) > 1;
}

async function passAccessibilityGateIfPresent(page) {
  const labels = ['Enable accessibility', 'Enable Accessibility'];

  if (await hasSemanticsEnabled(page)) return true;

  for (let i = 0; i < 4; i += 1) {
    const gateTriggered = await page.evaluate(() => {
      const gate = document.querySelector(
        'flt-semantics-placeholder[aria-label*="Enable accessibility" i]',
      );
      if (!gate) return false;
      const s = gate.style;
      s.position = 'fixed';
      s.left = '16px';
      s.top = '16px';
      s.width = '260px';
      s.height = '90px';
      s.opacity = '1';
      s.zIndex = '2147483647';
      s.pointerEvents = 'auto';
      gate.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }));
      gate.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
      gate.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
      gate.dispatchEvent(new MouseEvent('pointerup', { bubbles: true }));
      gate.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      gate.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
      gate.dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter', bubbles: true }));
      if (typeof gate.click === 'function') gate.click();
      return true;
    });
    if (gateTriggered) {
      await page.waitForTimeout(700);
      if (await hasSemanticsEnabled(page)) return true;
    }

    for (const frame of page.frames()) {
      for (const label of labels) {
        const gateButton = frame.getByRole('button', { name: label }).first();
        if ((await gateButton.count()) > 0) {
          try {
            await gateButton.click({ force: true, timeout: 1200 });
          } catch (_) {
            await gateButton.evaluate((el) => {
              el.dispatchEvent(new MouseEvent('click', { bubbles: true }));
              if (typeof el.click === 'function') el.click();
            });
          }
          await page.waitForTimeout(700);
          if (await hasSemanticsEnabled(page)) return true;
        }
      }
    }

    await page.waitForTimeout(600);
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
  await waitForLocatorWithGate(page, page.getByRole('heading', { name: labelPattern(appTitle) }));

  const anyModeButton = page
    .getByRole('button', {
      name: /Daily Verses|Guess the Chapter|Quiz|Read|Textual Structure/i,
    })
    .first();

  const started = Date.now();
  while (Date.now() - started < 25_000) {
    await passAccessibilityGateIfPresent(page);
    if ((await anyModeButton.count()) > 0 && (await anyModeButton.isVisible())) {
      return;
    }

    // In reader/quiz/etc. there is an unlabeled top-left control that returns to text options.
    const unlabeledBack = page.getByRole('button', { name: /^$/ }).first();
    if ((await unlabeledBack.count()) > 0) {
      try {
        await unlabeledBack.click({ timeout: 1500 });
      } catch (_) {
        await unlabeledBack.click({ force: true, timeout: 1500 });
      }
      await page.waitForTimeout(800);
      continue;
    }

    await page.waitForTimeout(800);
  }

  await expect(anyModeButton).toBeVisible({ timeout: 5_000 });
}

async function openMode(page, appPath, appTitle, modeLabel) {
  await openTextOptions(page, appPath, appTitle);
  const modeBtn = modeButton(page, modeLabel);
  await expect(modeBtn).toBeVisible();
  try {
    await modeBtn.click();
  } catch (_) {
    await modeBtn.click({ force: true });
  }
  await page.waitForTimeout(900);
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
