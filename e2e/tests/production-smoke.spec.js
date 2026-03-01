const { test, expect } = require('@playwright/test');
const { apps } = require('../apps');
const {
  openMode,
  openRead,
  openTextOptions,
  waitForLocatorWithGate,
  enterModeWithRetries,
  roleButton,
  labelPattern,
  firstVerseRefText,
  assertOrderedVerseSteps,
} = require('../helpers');

test.describe('dechen.study production smoke', () => {
  test('landing shows all app cards', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    await waitForLocatorWithGate(
      page,
      page.getByRole('group', { name: /Gateway to Knowledge/i }),
    );
    for (const app of apps) {
      await expect(page.getByRole('group', { name: labelPattern(app.title) })).toBeVisible();
    }
  });

  for (const app of apps) {
    test(`mode availability is correct for ${app.id}`, async ({ page }) => {
      await openTextOptions(page, app.path, app.title);

      for (const mode of app.modes) {
        await expect(roleButton(page, mode)).toBeVisible();
      }
    });

    test(`mode smoke coverage for ${app.id}`, async ({ page }) => {
      if (app.modes.includes('Daily Verses')) {
        await enterModeWithRetries(page, {
          appPath: app.path,
          appTitle: app.title,
          modeLabel: 'Daily Verses',
          isEntered: async () =>
            (await roleButton(page, 'More Verses').count()) > 0 ||
            (await roleButton(page, 'Another section').count()) > 0,
        });
        const moreVerses = roleButton(page, 'More Verses');
        const anotherSection = roleButton(page, 'Another section');
        if ((await moreVerses.count()) > 0) {
          await moreVerses.click();
        } else if ((await anotherSection.count()) > 0) {
          await anotherSection.click();
        }
      }

      if (app.modes.includes('Read')) {
        await openRead(page, app.path, app.title);
        await expect(page.getByText(/Verse\s+\d+/i).first()).toBeVisible();
      }

      if (app.modes.includes('Textual Structure')) {
        await enterModeWithRetries(page, {
          appPath: app.path,
          appTitle: app.title,
          modeLabel: 'Textual Structure',
          isEntered: async () =>
            (await page.getByRole('heading', { name: /Textual Structure/i }).count()) > 0,
        });
        await expect(page.getByRole('heading', { name: /Textual Structure/i })).toBeVisible();
      }

      if (app.modes.includes('Guess the Chapter')) {
        await enterModeWithRetries(page, {
          appPath: app.path,
          appTitle: app.title,
          modeLabel: 'Guess the Chapter',
          isEntered: async () => (await roleButton(page, 'Reveal').count()) > 0,
        });
        await expect(page.getByRole('heading', { name: /Guess the Chapter/i })).toBeVisible();
        await expect(roleButton(page, 'Reveal')).toBeVisible();
      }

      if (app.modes.includes('Quiz')) {
        await enterModeWithRetries(page, {
          appPath: app.path,
          appTitle: app.title,
          modeLabel: 'Quiz',
          isEntered: async () => (await roleButton(page, 'Reveal').count()) > 0,
        });
        await expect(roleButton(page, 'Reveal')).toBeVisible();
        await expect(roleButton(page, 'Skip')).toBeVisible();
      }
    });

    test(`reader key navigation stays ordered for ${app.id}`, async ({ page }) => {
      await openRead(page, app.path, app.title);

      const first = await firstVerseRefText(page);
      await page.locator('flutter-view').first().click({ force: true });

      const steps = [first];
      for (let i = 0; i < 25; i += 1) {
        await page.keyboard.press('ArrowDown');
        await page.waitForTimeout(250);
        steps.push(await firstVerseRefText(page));
      }

      const distinct = new Set(steps.map((s) => s.label));
      if (app.id === 'bodhicaryavatara') {
        expect(distinct.size).toBeGreaterThan(1);
      }
      assertOrderedVerseSteps(steps, 1);

      for (let i = 0; i < 3; i += 1) {
        await page.keyboard.press('ArrowUp');
        await page.waitForTimeout(450);
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
      await enterModeWithRetries(page, {
        appPath: quiz.path,
        appTitle: quiz.title,
        modeLabel: 'Quiz',
        isEntered: async () => (await roleButton(page, 'Reveal').count()) > 0,
      });
      await expect(roleButton(page, 'Reveal')).toBeVisible();

      if (quiz.advanced) {
        await expect(roleButton(page, 'Beginner')).toBeVisible();
        await expect(roleButton(page, 'Advanced')).toBeVisible();
        await roleButton(page, 'Advanced').click();
      } else {
        // Friendly Letter currently runs beginner-only without a difficulty toggle.
        await expect(roleButton(page, 'Beginner')).toHaveCount(0);
        await expect(roleButton(page, 'Advanced')).toHaveCount(0);
      }

      await roleButton(page, 'Reveal').click();
      await expect(page.getByText(/Answer/i).first()).toBeVisible();
      await roleButton(page, 'OK').click();

      await roleButton(page, 'Next').click();
      await expect(roleButton(page, 'Reveal')).toBeVisible();
    }
  });

  test('gateway app opens chapter detail', async ({ page }) => {
    await page.goto('/gateway-to-knowledge', { waitUntil: 'domcontentloaded' });
    await waitForLocatorWithGate(
      page,
      page.getByRole('heading', { name: /Gateway to Knowledge/i }),
    );
    await roleButton(page, 'Chapter 1').click();
    await expect(page.getByRole('heading', { name: /Gateway Chapter 1/i })).toBeVisible();
  });
});
