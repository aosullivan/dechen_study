const { test, expect } = require('@playwright/test');
const { apps } = require('../apps');
const {
  openMode,
  openRead,
  openTextOptions,
  firstVerseRefText,
  assertOrderedVerseSteps,
} = require('../helpers');

const allModeLabels = [
  'Daily Verses',
  'Guess the Chapter',
  'Quiz',
  'Read',
  'Textual Structure',
];

test.describe('dechen.study production smoke', () => {
  test('landing shows all app cards', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await expect(page.getByText('Gateway to Knowledge').first()).toBeVisible();
    for (const app of apps) {
      await expect(page.getByText(app.title).first()).toBeVisible();
    }
  });

  for (const app of apps) {
    test(`mode availability is correct for ${app.id}`, async ({ page }) => {
      await openTextOptions(page, app.path, app.title);

      for (const mode of app.modes) {
        await expect(page.getByText(mode, { exact: true })).toBeVisible();
      }

      for (const mode of allModeLabels.filter((label) => !app.modes.includes(label))) {
        await expect(page.getByText(mode, { exact: true })).toHaveCount(0);
      }
    });

    test(`mode smoke coverage for ${app.id}`, async ({ page }) => {
      if (app.modes.includes('Daily Verses')) {
        await openMode(page, app.path, app.title, 'Daily Verses');
        await expect(page.getByText('Another section', { exact: true })).toBeVisible();
        await expect(page.getByText('Full text', { exact: true })).toBeVisible();
        await page.getByText('Another section', { exact: true }).click();
      }

      if (app.modes.includes('Read')) {
        await openRead(page, app.path, app.title);
        await expect(page.locator('text=/^Verse\\s+\\d+(?:\\.\\d+)?$/').first()).toBeVisible();
      }

      if (app.modes.includes('Textual Structure')) {
        await openMode(page, app.path, app.title, 'Textual Structure');
        await expect(page.getByText('Textual Structure').first()).toBeVisible();
      }

      if (app.modes.includes('Guess the Chapter')) {
        await openMode(page, app.path, app.title, 'Guess the Chapter');
        await expect(page.getByText('Guess the Chapter').first()).toBeVisible();
        await expect(page.getByText('Reveal', { exact: true })).toBeVisible();
      }

      if (app.modes.includes('Quiz')) {
        await openMode(page, app.path, app.title, 'Quiz');
        await expect(page.getByText('Quiz').first()).toBeVisible();
        await expect(page.getByText('Reveal', { exact: true })).toBeVisible();
        await expect(page.getByText('Skip', { exact: true })).toBeVisible();
      }
    });

    test(`reader key navigation stays ordered for ${app.id}`, async ({ page }) => {
      await openRead(page, app.path, app.title);

      const first = await firstVerseRefText(page);
      await page.getByText(first.label, { exact: true }).first().click();

      const steps = [first];
      for (let i = 0; i < 8; i += 1) {
        await page.keyboard.press('ArrowDown');
        await page.waitForTimeout(350);
        steps.push(await firstVerseRefText(page));
      }

      const distinct = new Set(steps.map((s) => s.label));
      expect(distinct.size).toBeGreaterThan(2);
      assertOrderedVerseSteps(steps, 1);

      for (let i = 0; i < 3; i += 1) {
        await page.keyboard.press('ArrowUp');
        await page.waitForTimeout(300);
      }
      const backStep = await firstVerseRefText(page);
      expect(backStep.chapter <= steps[steps.length - 1].chapter).toBeTruthy();
    });
  }

  test('quiz options matrix and basic functionality are correct', async ({ page }) => {
    const expectations = [
      { path: '/friendlyletter', title: 'Friendly Letter', advanced: false },
      {
        path: '/lampofthepath',
        title: 'Lamp of the Path to Enlightenment',
        advanced: true,
      },
      { path: '/bodhicaryavatara', title: 'Bodhicaryavatara', advanced: true },
    ];

    for (const quiz of expectations) {
      await openMode(page, quiz.path, quiz.title, 'Quiz');

      await expect(page.getByText('Beginner', { exact: true })).toBeVisible();
      if (quiz.advanced) {
        await expect(page.getByText('Advanced', { exact: true })).toBeVisible();
        await page.getByText('Advanced', { exact: true }).click();
      } else {
        await expect(page.getByText('Advanced', { exact: true })).toHaveCount(0);
      }

      await page.getByText('Reveal', { exact: true }).click();
      await expect(page.getByText('Answer').first()).toBeVisible();
      await page.getByText('OK', { exact: true }).click();

      await page.getByText('Next', { exact: true }).click();
      await expect(page.getByText('Reveal', { exact: true })).toBeVisible();
    }
  });

  test('gateway app opens chapter detail', async ({ page }) => {
    await page.goto('/gateway-to-knowledge', { waitUntil: 'domcontentloaded' });
    await expect(page.getByText('Gateway to Knowledge').first()).toBeVisible();
    await page.getByText(/Chapter 1:/).first().click();
    await expect(page.getByText('Gateway Chapter 1').first()).toBeVisible();
  });
});
