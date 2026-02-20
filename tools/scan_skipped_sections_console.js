// Paste this IIFE into Chrome DevTools Console.
// Update selectors in CFG for your page before running.
(async () => {
  if (window.__skipScannerRunning) {
    console.warn(
      "Scanner already running. Set window.__skipScannerStop = true to stop it.",
    );
    return;
  }

  window.__skipScannerRunning = true;
  window.__skipScannerStop = false;

  const CFG = {
    // REQUIRED: all section rows in nav/list order
    sectionItemSelector: ".section-item",

    // REQUIRED: currently active/highlighted section in the nav/list
    activeSectionSelector:
      ".section-item.active, .section-item.selected, .section-item[aria-current='true']",

    // REQUIRED: element containing the current verse ref (e.g. 6.36ab)
    verseSelector:
      ".verse.active .verse-ref, .current-verse .verse-ref, [data-current-verse]",

    // Optional: use button click instead of ArrowDown key
    nextButtonSelector: null, // e.g. ".next-button"

    nextKey: "ArrowDown",
    stepDelayMs: 220,
    maxSteps: 25000,
    idleStepsToStop: 12,
  };

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const sleep = (ms) => new Promise((res) => setTimeout(res, ms));
  const clean = (s) => (s || "").replace(/\s+/g, " ").trim();

  function parseSectionText(raw) {
    const text = clean(raw);
    const numMatch = text.match(/\b(\d+(?:\.\d+)+)\b/); // full hierarchical section number
    const fullHierarchy = numMatch ? numMatch[1] : "";
    const chapter = fullHierarchy ? fullHierarchy.split(".")[0] : "";
    const name = clean(text.replace(fullHierarchy, "")) || "(unnamed section)";
    return { chapter, fullHierarchy, name, raw: text };
  }

  function parseVerse(raw) {
    const text = clean(raw);
    const m = text.match(/\b\d+\.\d+[a-z]*\b/i); // supports 6.36ab
    return m ? m[0] : text || "";
  }

  const sectionRows = $$(CFG.sectionItemSelector).map((el, index) => {
    const p = parseSectionText(el.innerText || el.textContent || "");
    return { ...p, el, index };
  });

  if (!sectionRows.length) {
    window.__skipScannerRunning = false;
    throw new Error("No sections found. Update CFG.sectionItemSelector.");
  }

  function findCurrentSection() {
    const activeEl = $(CFG.activeSectionSelector);
    if (!activeEl) return null;

    // First try direct element match.
    let hit = sectionRows.find((s) => s.el === activeEl);
    if (hit) return hit;

    // Fallback by hierarchy number.
    const parsed = parseSectionText(activeEl.innerText || activeEl.textContent || "");
    if (parsed.fullHierarchy) {
      hit = sectionRows.find((s) => s.fullHierarchy === parsed.fullHierarchy);
      if (hit) return hit;
    }

    // Fallback by normalized name.
    hit = sectionRows.find((s) => s.name === parsed.name);
    return hit || null;
  }

  function findCurrentVerse() {
    const el = $(CFG.verseSelector);
    if (!el) return "";
    return parseVerse(el.innerText || el.textContent || "");
  }

  function getState() {
    return {
      section: findCurrentSection(),
      verse: findCurrentVerse(),
    };
  }

  function pressKey(key) {
    const target = document.activeElement || document.body;
    const down = new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
    });
    const up = new KeyboardEvent("keyup", { key, bubbles: true, cancelable: true });
    target.dispatchEvent(down);
    target.dispatchEvent(up);
  }

  async function goNext() {
    if (CFG.nextButtonSelector) {
      const btn = $(CFG.nextButtonSelector);
      if (!btn) throw new Error("nextButtonSelector not found.");
      btn.click();
    } else {
      pressKey(CFG.nextKey);
    }
  }

  const skippedLogs = [];
  let state = getState();
  let idle = 0;

  // "previous section to have a verse"
  let lastSectionWithVerse = state.section || null;
  let lastVerse = state.verse || "";

  for (let i = 0; i < CFG.maxSteps; i++) {
    if (window.__skipScannerStop) break;

    const prev = state;

    await goNext();
    await sleep(CFG.stepDelayMs);

    state = getState();

    if (state.verse) {
      lastVerse = state.verse;
      if (state.section) lastSectionWithVerse = state.section;
    }

    if (prev.section && state.section && state.section.index > prev.section.index + 1) {
      for (let k = prev.section.index + 1; k < state.section.index; k++) {
        const missed = sectionRows[k];
        const row = {
          chapter: missed.chapter || "(unknown)",
          section_name: missed.name,
          full_hierarchical_number: missed.fullHierarchy || "(unknown)",
          previous_verse: lastVerse || "(no verse found yet)",
          verse_from_section: lastSectionWithVerse
            ? `${lastSectionWithVerse.fullHierarchy} ${lastSectionWithVerse.name}`
            : "(no prior section with verse found)",
        };
        skippedLogs.push(row);
        console.log("[SKIPPED SECTION]", row);
      }
    }

    const noChange =
      prev.section?.index === state.section?.index &&
      (prev.verse || "") === (state.verse || "");
    idle = noChange ? idle + 1 : 0;
    if (idle >= CFG.idleStepsToStop) break;
  }

  window.__skippedSections = skippedLogs;
  window.__skipScannerRunning = false;

  console.log(`Done. Skipped sections found: ${skippedLogs.length}`);
  if (skippedLogs.length) console.table(skippedLogs);
})();
