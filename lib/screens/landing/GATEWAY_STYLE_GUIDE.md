# Gateway Visual Style Guide

Design principles and visual vocabulary for all Gateway to Knowledge chapter screens.

---

## 1. Design Principles

- **Compact** — minimise padding, spacing, and font sizes; density over whitespace.
- **Clarity** — every visual element has a specific semantic meaning.
- **Consistency** — same concept always uses the same colour, icon, and connector.
- **No coloured backdrops** — items use icon badges for colour coding, not full-width coloured bars.

---

## 2. Colour System

Colours encode semantic category. Each classification uses a distinct hue family:

| Classification   | Hue Family           | Mnemonic                         |
|------------------|----------------------|----------------------------------|
| **Skandhas**     | **Reds**             | Aggregates = warm / embodied     |
| **Dhatus**       | **Yellows / Oranges / Whites** | Elements = earthy spectrum |
| **Ayatanas**     | **Blues / Greens**    | Sources = cool / perceptual      |

### Dhatu triad colours (`_TriadCategory`)

| Category             | Background   | Border       | Icon         | Hue        |
|----------------------|-------------|-------------|-------------|------------|
| **Faculties**        | `#FFF9C4`   | `#C8A830`   | `#7A6000`   | Lemon gold |
| **Objects**          | `#FFE6C0`   | `#CC8838`   | `#96490A`   | Burnt orange|
| **Consciousnesses**  | `#FFFFFE`   | `#D4C0A4`   | `AppColors.primary` | White/neutral |

### Skandha colours (reds)

| Role             | Background   | Border       | Icon         |
|------------------|-------------|-------------|-------------|
| Badge            | `#FDEBEA`   | `#CF9290`   | `#9E3532`   |
| Chip             | `#FDF0EF`   | `#D4A09E`   | —            |

### Ayatana source colours (green + blue)

| Role                 | Background   | Border       | Icon         | Hue        |
|----------------------|-------------|-------------|-------------|------------|
| **Inner** (green)    | `#E6F4EC`   | `#88C4A0`   | `#2E7D52`   | Forest green |
| **Outer** (blue)     | `#E4EEF6`   | `#85B0D4`   | `#2C5F8A`   | Steel blue |

Inner uses green (what apprehends); outer uses blue (what is apprehended). Distinct hue families for instant differentiation.

### Surface colours

| Surface              | Colour       | Usage                                  |
|----------------------|-------------|----------------------------------------|
| Card background      | `AppColors.cardBeige` (`#F4ECDD`) | Topic card fill       |
| Header pill          | `#FFF4E0`   | Section headers, triad-note pills      |
| Header pill border   | `#DDD0B8`   | Pill and header borders                |
| Callout background   | `#FFF2DA`   | Left-bordered callout blocks           |
| Grid card background | `#FFFBF4`   | Icon-list-grid items, triad cards      |
| Grid card border     | `#E0D3BF`   | Grid item and triad card borders       |
| Chip background      | `#FFF5E4`   | Cross-reference topic chips            |
| Chip border          | `#DDcEB8`   | Chip borders                           |
| Table header         | `#F4E8D5`   | Table header row background            |
| Map container        | `#FFFBF4`   | Ayatana-dhatu outer wrapper            |
| Map container border | `#DDCDB6`   | Map wrapper border                     |
| _IconBadge default border | `#D6C5AA` | When no category colour specified   |

---

## 3. Connectors

Two distinct connector types with different semantics:

### Perception Connector (`_PerceptionConnector`)
- **Meaning**: "apprehends" — an inner source perceives an outer source.
- **Visual**: horizontal line with a forward arrow `→`.
- **Used in**: Inner and Outer Sources pairing view.

### Identity Connector (`_IdentityConnector`)
- **Meaning**: "corresponds to" / "equals" — structural equivalence.
- **Visual**: triple-bar equals sign `≡`.
- **Used in**: Ayatana-to-Dhatu mapping table.

> Never mix these connectors. Arrows imply directionality/agency; `≡` implies structural identity.

---

## 4. Icon Badges

All element/concept labels are prefixed with a circular `_IconBadge`.

- Badge sizes scale with context: topic title (15), section headers (10–12), list items (9–12).
- Badge colour matches its category:
  - **Skandha** → red badge (`#9E3532` icon, `#FDEBEA` bg)
  - **Faculty dhatu** → lemon-gold badge (`#7A6000` icon, `#FFF9C4` bg)
  - **Object dhatu** → burnt-orange badge (`#96490A` icon, `#FFE6C0` bg)
  - **Consciousness dhatu** → neutral badge (`AppColors.primary` icon, white bg)
  - **Ayatana inner** → green badge (`#2E7D52` icon, `#E6F4EC` bg)
  - **Ayatana outer** → blue badge (`#2C5F8A` icon, `#E4EEF6` bg)
- Icons are Material `_outlined` variants chosen by `_iconForLabel()`.
- Items do NOT use coloured background bars; colour lives only in the badge.

---

## 5. Typography Scale

| Context              | Font Size | Weight | Notes                       |
|----------------------|-----------|--------|-----------------------------|
| Topic title          | 20        | w600   | Crimson Text / titleLarge   |
| Section header       | 12–13     | w700   | Headers, map head chips     |
| Body / topic-copy    | 13.5      | normal | Main descriptive text       |
| Callout              | 13.5      | normal | Left-bordered highlight     |
| Triad-note pill      | 12.5      | normal | Intro summary pill          |
| List items           | 12–13.5   | normal | Plain lists, grid items     |
| Map node labels      | 12        | w600   | Ayatana/dhatu labels        |
| Chip labels          | 13        | w400/600 | Topic cross-reference chips |
| Triad card title     | 13        | w700   | Faculty/Object/Consc. header|
| Triad card items     | 12.5      | normal | Element names within triads |
| Consciousness stack  | 13        | normal | Vertical element items      |

---

## 6. Spacing Rules

| Element                  | Value  | Notes                         |
|--------------------------|--------|-------------------------------|
| ListView padding         | 10h, 8t, 16b | Outer scroll area       |
| Card internal padding    | 9h, 7v | Topic card wrapper            |
| Title → divider          | 4      |                               |
| Divider → content        | 3      |                               |
| Card bottom margin       | 6      | Between topic cards           |
| Between triad cards      | 5      |                               |
| Duality pair rows        | 2      | Between inner/outer pairs     |
| Map rows                 | 3      | Between ayatana–dhatu rows    |
| Consciousness stack gap  | 2      | Between stacked items         |
| Icon → label gap         | 5–6    | Inside nodes and list items   |

---

## 7. Widget Taxonomy

| Widget                        | Purpose                                           |
|-------------------------------|---------------------------------------------------|
| `_GatewayTopicCard`           | Top-level card for each topic                     |
| `_TriadCards` / `_TriadCard`  | Three-column faculty/object/consciousness view    |
| `_DualityPairView`            | Inner ↔ Outer source pairing (perception arrows)  |
| `_AyatanaDhatuMapView`        | 12 ayatana ≡ 18 dhatu mapping                     |
| `_AyatanaMapRow`              | Single mapping row (or mind row with 7 items)      |
| `_AyatanaMapNode`             | Plain icon-badge + label (no backdrop)             |
| `_ConsciousnessStackItem`     | Plain icon-badge + label for consciousness lists   |
| `_PerceptionConnector`        | Arrow connector (inner → outer)                    |
| `_IdentityConnector`          | Equivalence connector (≡)                          |
| `_IconBadge`                  | Circular icon with category colouring              |
| `_GatewayChipLink`            | Cross-reference chip for topic navigation          |
| `_PlainList`                  | Numbered or bulleted text list                     |
| `_ClassificationSummaryList`  | Classification items with inline icon chips        |

---

## 8. Style Classes (data → renderer mapping)

| `styleClass`            | Renderer                    | Notes                            |
|-------------------------|-----------------------------|----------------------------------|
| `sense-list`            | `_TriadCards`               | Three consecutive = triad        |
| `sense-list-subset`     | Skipped (shown via summary) | Greyed-out subset lists          |
| `duality-list`          | `_DualityPairView`          | Two consecutive = inner/outer    |
| `consciousness-stack`   | `_ConsciousnessStackItem`   | Vertical items, gold Mind El.    |
| `icon-list-grid`        | Wrap grid with icon badges  | General icon-prefixed items      |
| `links-grid`            | Wrap grid with numbers      | Numbered reference items         |
| `ayatana-dhatu-map`     | `_AyatanaDhatuMapView`      | Custom mapping view              |
| `classification-summary`| `_ClassificationSummaryList`| Expandable classification items  |
| `triad-note`            | Pill container              | Intro text in rounded pill       |
| `callout`               | Left-bordered box           | Highlighted explanatory text     |
| `topic-copy`            | Plain paragraph             | Body text                        |
| `subset-title`          | Italic section header       | Classification sub-heading       |
