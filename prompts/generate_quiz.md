# Quiz Generation Prompt

Use this prompt to generate a beginner multiple-choice quiz for a Buddhist root text. Provide the prompt below along with:
1. The **root text** (all verses)
2. The **verse-to-section commentary mapping** (so the quiz can draw on thematic context)
3. Optionally, an **example quiz** from another text to match the style

---

## Prompt

You are generating a 200-question beginner multiple-choice quiz for the root text provided below. Follow these rules exactly:

### Question Quality

- Every question must be **specific and self-contained**. A reader should understand exactly what is being asked without needing to see the verse first.
- **NEVER** use ambiguous indexicals like "here", "this passage", "the above verse", or "this section". The question must name or describe its subject explicitly (e.g. "What analogy does the text use for sensual pleasures?" NOT "Which teaching is being emphasized here?").
- **NEVER** repeat the same question stem. Vary the question types across the quiz. Good types include:
  - "What analogy does [author] use for X?"
  - "What are the [N] things listed as X?"
  - "According to the text, what is X?"
  - "Which of the following is NOT one of the X?"
  - "To what is X compared?"
  - "What happens when / after X?"
  - "What does the text say about X?"
  - "Who is described as X?"
  - "What remedy does the text give for X?"
  - "How does the text illustrate X?"
  - "What stage / result is attained by doing X?"
  - "Complete the verse: '...'"
  - "What [N] qualities describe X?"
  - "Which of the following is one of the X listed in the text?"

### Answer Choices

- Provide exactly **four choices** (a–d), with **one correct answer**.
- **Distractors** must be plausible — draw them from:
  - Other parts of the same text (different verses, different lists)
  - Related Buddhist concepts from the same tradition that a beginner might confuse
  - Slight distortions of the correct answer (e.g. swapping one item in a list)
- Distractors should **never be absurd or obviously wrong** to someone unfamiliar with the text.
- The correct answer should use **wording close to the root text** so the quiz reinforces the actual language of the text.

### Coverage

- Cover **all verses** of the root text systematically, roughly in order.
- Richer verses (those with lists, analogies, or key doctrinal points) should get **2–3 questions**.
- Simpler verses get **1 question**.
- Aim for even distribution — don't cluster all questions around a few popular verses.

### Format

Use this exact format for every question:

```
Q[N]. [Specific, self-contained question]
a) [Choice]
b) [Choice]
c) [Choice]
d) [Choice]
ANSWER: [letter]
VERSE REF(S): [verse number(s)]
VERSE TEXT:
[Full text of the referenced verse(s), with verse numbers in brackets]
```

### What to Avoid

- **No ambiguous pronouns or indexicals** — never "here", "this", "the above", "the following"
- **No repeated question stems** — if you catch yourself writing the same phrasing twice, rewrite it
- **No questions that give away the answer** — the question should test recall, not reading comprehension of the question itself
- **No commentary-only questions** — questions should be answerable from the root text (the commentary mapping is for your thematic understanding, not for testing the student)
- **No overly long answer choices** — keep each choice to 1–2 lines maximum
- **No trick questions** — the quiz is for beginners learning the text

### Tone

The quiz should feel like a knowledgeable study companion helping someone internalise the text. Questions should spark recognition ("Oh yes, that's the verse about the leper and the fire!") rather than confusion.
