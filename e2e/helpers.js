const { expect } = require('@playwright/test');

async function openTextOptions(page, appPath, appTitle) {
  await page.goto(appPath, { waitUntil: 'domcontentloaded' });
  await expect(page.getByText(appTitle).first()).toBeVisible();
}

async function openMode(page, appPath, appTitle, modeLabel) {
  await openTextOptions(page, appPath, appTitle);
  await page.getByText(modeLabel, { exact: true }).click();
}

async function openRead(page, appPath, appTitle) {
  await openMode(page, appPath, appTitle, 'Read');

  // Multi-chapter texts show a chapter picker first.
  const chapterOneTile = page.getByText(/^1\.$/).first();
  if ((await chapterOneTile.count()) > 0) {
    await chapterOneTile.click();
  }

  await expect(firstVerseRefLocator(page)).toBeVisible();
}

function firstVerseRefLocator(page) {
  return page.locator('text=/^Verse\\s+\\d+(?:\\.\\d+)?$/').first();
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
  openTextOptions,
  openMode,
  openRead,
  firstVerseRefText,
  assertOrderedVerseSteps,
};
