# Production E2E (Manual Run)

This suite runs real-browser checks against production (`https://www.dechen.study` by default).

## Install

```bash
npm install
npx playwright install chromium
```

## Run

```bash
npm run test:e2e
```

Optional headed run:

```bash
npm run test:e2e:headed
```

Optional explicit URL override:

```bash
BASE_URL=https://www.dechen.study npm run test:e2e
```

## What is covered

- Landing + all app cards.
- Mode availability matrix for each text app.
- Smoke checks for Daily, Read, Textual Structure, Guess the Chapter, and Quiz.
- Reader arrow-key progression from the start, asserting ordered movement and no verse skipping in section navigation.
- Quiz option matrix:
  - `friendlyletter`: Beginner only.
  - `lampofthepath`: Beginner + Advanced.
  - `bodhicaryavatara`: Beginner + Advanced.
- Quiz basic flow (`Reveal` -> `Answer` dialog -> `Next`).
- Gateway app chapter open.
