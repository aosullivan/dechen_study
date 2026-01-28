# Study App - Architecture & Design

## Overview

A Flutter-based text study application with Supabase backend, featuring authentication, daily study sections, and interactive quizzes.

## Technology Stack

### Frontend
- **Flutter** 3.24+ - Cross-platform UI framework
- **Dart** - Programming language
- **Google Fonts** - Typography (Cormorant Garamond, Crimson Text)

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Authentication (email with confirmation)
  - Row Level Security (RLS)
  - RESTful API

### State Management
- **StatefulWidget** - Built-in Flutter state management
- Simple, suitable for app complexity

## Architecture Pattern

### Model-View-Controller (MVC) Pattern

```
lib/
├── models/          # Data models (Chapter, Section)
├── screens/         # Views (UI)
│   ├── auth/       # Authentication views
│   └── study/      # Study feature views
└── main.dart       # App initialization
```

### Data Flow

```
User Input → UI (Screen) → Supabase Client → Database
                ↓
            Update State
                ↓
           Re-render UI
```

## Database Schema

### Entity Relationship Diagram

```
┌─────────────┐       ┌──────────────┐
│  chapters   │──────<│   sections   │
├─────────────┤       ├──────────────┤
│ id          │       │ id           │
│ number      │       │ chapter_id   │
│ title       │       │ content      │
└─────────────┘       │ order_index  │
                      └──────────────┘

┌──────────────────┐       ┌──────────────────┐
│  user_progress   │       │ daily_progress   │
├──────────────────┤       ├──────────────────┤
│ id               │       │ id               │
│ user_id          │       │ user_id          │
│ current_section  │       │ date             │
│ _index           │       │ section_id       │
└──────────────────┘       └──────────────────┘
```

### Table Purposes

**chapters**
- Stores chapter metadata
- One chapter has many sections
- Fields: id, chapter_number, title

**sections**
- Stores text content broken into sections
- Belongs to one chapter
- Fields: id, chapter_id, content, order_index

**user_progress**
- Tracks each user's current position in the text
- One record per user
- Increments section_index when daily section completed

**daily_progress**
- Records daily completions
- One record per user per day
- Prevents multiple completions same day

## Security Model

### Row Level Security (RLS)

**chapters & sections** (Public read, admin write)
- Everyone can SELECT
- Only admin can INSERT/UPDATE/DELETE

**user_progress** (Private)
- Users can only access their own records
- Policy: `auth.uid() = user_id`

**daily_progress** (Private)
- Users can only access their own records
- Policy: `auth.uid() = user_id`

### Authentication Flow

```
1. User signs up
   ↓
2. Supabase sends confirmation email
   ↓
3. User clicks link
   ↓
4. Email confirmed
   ↓
5. User can sign in
   ↓
6. Session token stored
   ↓
7. Auto sign-in on app restart
```

## Feature Architecture

### Daily Section Feature

**Logic:**
1. Check if user completed today (query daily_progress)
2. If completed, show success screen
3. If not completed:
   - Get user's current_section_index
   - Fetch section at that index
   - Display section
   - On "Mark Complete":
     - Insert into daily_progress
     - Increment current_section_index

**Edge Cases:**
- First-time user: Initialize with index 0
- Last section reached: Wrap around to 0
- Multiple devices: Last write wins

### Quiz Feature

**Logic:**
1. Get all sections with chapter info
2. Pick random section
3. Get correct chapter number
4. Generate 3 wrong answers (other chapter numbers)
5. Shuffle options
6. Present to user
7. Check answer and show feedback
8. Track score in local state

### Read Text Feature

**Logic:**
1. Fetch all chapters
2. Fetch all sections grouped by chapter
3. Display in expandable list
4. Sections shown when chapter expanded

## UI/UX Design

### Design System

**Colors:**
- Primary: Gold (#D4AF37)
- Background: Warm Beige (#FAF8F3)
- Text: Dark Brown (#2C2416, #4A4238)
- Accent: Muted Gold variations

**Typography:**
- Headings: Cormorant Garamond (serif, elegant)
- Body: Crimson Text (serif, readable)
- Sizes: Display (36), Headline (24-28), Body (16-18)

**Spacing:**
- Base unit: 8px
- Padding: 16px, 24px
- Margins: 8px, 16px, 24px, 32px

**Components:**
- Cards: White bg, subtle border, minimal shadow
- Buttons: Gold, rounded corners (8px)
- Inputs: White bg, border, focused gold border

### Navigation

**Bottom Navigation Bar:**
- Home
- Read
- Daily
- Quiz

**Benefits:**
- Familiar mobile pattern
- Easy thumb access
- Always visible
- Clear context

### Responsive Design

**Mobile First:**
- Design for 375px width (iPhone SE)
- Scale up for tablets/web

**Breakpoints:**
- Mobile: < 600px
- Tablet: 600px - 1024px
- Desktop: > 1024px

**Adaptations:**
- Max width on desktop (800px)
- Centered content
- Larger touch targets on mobile

## Performance Considerations

### Optimization Strategies

**Database:**
- Indexes on foreign keys
- Efficient queries (select only needed fields)
- Pagination for large datasets

**Flutter:**
- const constructors where possible
- ListView.builder for long lists
- Image caching
- Lazy loading

**Network:**
- Batch requests when possible
- Cache responses
- Retry logic for failures

### Metrics to Monitor

- App startup time (target: < 2s)
- Screen transition time (target: < 100ms)
- Network request time (target: < 1s)
- Memory usage
- Battery consumption

## Testing Strategy

### Unit Tests
- Data models
- Parsing logic
- Business logic

### Widget Tests
- Individual screens
- User interactions
- State changes

### Integration Tests
- End-to-end flows
- Authentication
- Database operations

### Manual Testing
- Different screen sizes
- Different OS versions
- Offline behavior
- Email confirmation flow

## Error Handling

### Strategy
1. Try-catch all async operations
2. Display user-friendly messages
3. Log errors for debugging
4. Graceful degradation

### Error Types

**Network Errors:**
- No connection: Show offline message
- Timeout: Retry with exponential backoff
- Server error: Show generic error

**Auth Errors:**
- Invalid credentials: Show specific message
- Email not confirmed: Prompt to check email
- Session expired: Redirect to login

**Data Errors:**
- No data: Show empty state
- Invalid data: Skip and continue
- Sync conflict: Last write wins

## Accessibility

### Compliance
- WCAG 2.1 Level AA target

### Features
- Semantic labels on all interactive elements
- Sufficient color contrast (4.5:1 for normal text)
- Keyboard navigation support (web)
- Screen reader support
- Scalable text

## Future Enhancements

### Phase 2 Features
- [ ] Bookmarking sections
- [ ] Notes and annotations
- [ ] Highlighting text
- [ ] Search functionality
- [ ] Multiple texts support
- [ ] Dark mode

### Phase 3 Features
- [ ] Social features (groups, sharing)
- [ ] Progress statistics/charts
- [ ] Reminders/notifications
- [ ] Offline support
- [ ] Audio narration
- [ ] Translation support

### Technical Debt
- [ ] Add comprehensive tests
- [ ] Implement proper state management (Riverpod/Bloc)
- [ ] Add analytics
- [ ] Add error tracking (Sentry)
- [ ] Improve caching
- [ ] Add pagination

## Development Workflow

### Git Workflow
1. Feature branches from main
2. Pull request for review
3. Merge to main
4. Auto-deploy via CI/CD

### Code Style
- Follow Dart style guide
- Use linter (flutter_lints)
- Format before commit (`dart format .`)

### Release Process
1. Update version in pubspec.yaml
2. Update CHANGELOG.md
3. Create git tag
4. Build and test
5. Deploy to production
6. Monitor for issues

## Monitoring and Analytics

### Metrics to Track
- Daily active users
- Retention rate
- Feature usage
- Session duration
- Error rates
- Performance metrics

### Tools (Recommended)
- Firebase Analytics
- Sentry (error tracking)
- Supabase dashboard (database metrics)

## Deployment Architecture

### Web
```
User → CDN (Netlify/Vercel) → Static Files
                ↓
        Supabase API ← Database
```

### Mobile
```
User → App Store/Play Store → App Install
                ↓
        Supabase API ← Database
```

### Benefits
- Serverless (no server to manage)
- Auto-scaling
- Global CDN
- Built-in auth
- Real-time capabilities (if needed)

## Cost Analysis

### Development Costs
- Developer time: Variable
- Design: Minimal (using template)
- Testing: Included

### Operational Costs
- Supabase Free: $0/month (good for MVP)
- Supabase Pro: $25/month (production)
- Hosting: $0 (Netlify/Vercel free tier)
- Domain: $10-15/year
- Apple Developer: $99/year
- Google Play: $25 one-time

### Scaling Costs
- Supabase Team: $599/month (higher limits)
- Custom enterprise: Contact sales

## Compliance and Legal

### Required
- Privacy Policy
- Terms of Service
- Cookie Policy (if applicable)
- Data retention policy
- GDPR compliance (if EU users)

### Recommended
- About page
- Contact information
- Attribution for open source libraries

## Documentation

### User Documentation
- README.md - Overview and quick start
- SETUP.md - Detailed setup instructions
- DEPLOYMENT.md - Production deployment
- FAQ - Common questions

### Developer Documentation
- This file (ARCHITECTURE.md)
- Code comments
- API documentation
- Database schema docs

## Maintenance Plan

### Regular Tasks
- Update dependencies monthly
- Security patches immediately
- Review error logs weekly
- Monitor performance monthly
- Database backups (automatic via Supabase)

### Emergency Procedures
- Rollback plan
- Database restore process
- Communication plan (users)
- Incident response

---

## Summary

This architecture provides:
- ✅ Scalable backend (Supabase)
- ✅ Cross-platform UI (Flutter)
- ✅ Secure authentication
- ✅ Clean, maintainable code
- ✅ Room for growth
- ✅ Cost-effective operation
- ✅ Professional design

The design prioritizes simplicity, user experience, and maintainability while providing a solid foundation for future enhancements.
