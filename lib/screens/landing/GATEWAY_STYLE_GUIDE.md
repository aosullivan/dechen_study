# Gateway Visual Style Guide

Design principles and visual vocabulary for all Gateway to Knowledge chapter screens.

---

## 1. Design Principles

- **Compact** — minimise padding, spacing, and font sizes; density over whitespace.
- **Clarity** — every visual element has a specific semantic meaning.
- **Consistency** — same concept always uses the same colour, icon, and connector.

---

## 2. Colour Palette

### Category colours (Dhatu triads)

| Category         | Background   | Border       | Icon         | Usage                    |
|------------------|-------------|-------------|-------------|--------------------------|
| **Faculties**    | `#FFF8E1`   | `#E8D99A`   | `#B8960F`   | Warm amber/yellow        |
| **Objects**      | `#ECF1F9`   | `#B8C8DC`   | `#4A6FA5`   | Cool blue-grey           |
| **Consciousnesses** | `#FFFFFF` | `#E6D8C3`   | `AppColors.primary` | White, neutral border |

### Ayatana source colours (green spectrum)

| Role             | Background   | Border       | Icon         |
|------------------|-------------|-------------|-------------|
| **Inner** (lighter) | `#F0F8F4` | `#C8E2D4`   | `#7EAE96`   |
| **Outer** (darker)  | `#E6F0EA` | `#A3C9B3`   | `#3D6B56`   |

Inner and outer use the same green hue family, differentiated only by lightness.

### Skandha colours

| Role             | Background   | Border       | Icon         |
|------------------|-------------|-------------|-------------|
| Badge            | `#FFF0EF`   | `#E0B4B1`   | `#C07A75`   |
| Chip             | `#FFF5F4`   | `#E8C4C2`   | —            |

### Surface colours

| Surface          | Colour       | Usage                                  |
|------------------|-------------|----------------------------------------|
| Card background  | `AppColors.cardBeige` | Topic card fill                 |
| Row container    | `#FFFCF7`   | Mapping row wrapper                    |
| Header pill      | `#FFF8EE`   | Section headers, triad-note pills      |
| Callout          | `#FFF7EA`   | Left-bordered callout blocks           |

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

- Badge sizes scale with context: topic title (15), section headers (10–12), list items (8–11).
- Badge colour matches its category (faculty amber, object blue, consciousness neutral, ayatana green).
- Icons are Material `_outlined` variants chosen by `_iconForLabel()`.

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
| Map node labels      | 11        | w600   | Ayatana/dhatu bar labels    |
| Chip labels          | 13        | w400/600 | Topic cross-reference chips |
| Triad card title     | 13        | w700   | Faculty/Object/Consc. header|
| Triad card items     | 12.5      | normal | Element names within triads |
| Consciousness stack  | 12        | normal | Vertical element bars       |

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
| Duality pair rows        | 3      | Between inner/outer pairs     |
| Map rows                 | 3      | Between ayatana–dhatu rows    |
| Consciousness stack gap  | 2      | Between stacked bars          |
| Icon → label gap         | 4–5    | Inside bars and nodes         |

---

## 7. Widget Taxonomy

| Widget                        | Purpose                                           |
|-------------------------------|---------------------------------------------------|
| `_GatewayTopicCard`           | Top-level card for each topic                     |
| `_TriadCards` / `_TriadCard`  | Three-column faculty/object/consciousness view    |
| `_DualityPairView`            | Inner ↔ Outer source pairing (perception arrows)  |
| `_AyatanaDhatuMapView`        | 12 ayatana ≡ 18 dhatu mapping                     |
| `_AyatanaMapRow`              | Single mapping row (or mind row with 7 bars)       |
| `_AyatanaMapNode`             | Single coloured bar with icon + label              |
| `_ConsciousnessStackItem`     | Compact vertical bar for consciousness lists       |
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
| `consciousness-stack`   | `_ConsciousnessStackItem`   | Vertical bars, yellow Mind El.   |
| `icon-list-grid`        | Wrap grid with icon badges  | General icon-prefixed items      |
| `links-grid`            | Wrap grid with numbers      | Numbered reference items         |
| `ayatana-dhatu-map`     | `_AyatanaDhatuMapView`      | Custom mapping table             |
| `classification-summary`| `_ClassificationSummaryList`| Expandable classification items  |
| `triad-note`            | Pill container              | Intro text in rounded pill       |
| `callout`               | Left-bordered box           | Highlighted explanatory text     |
| `topic-copy`            | Plain paragraph             | Body text                        |
| `subset-title`          | Italic section header       | Classification sub-heading       |
