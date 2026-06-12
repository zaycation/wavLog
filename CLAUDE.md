# WavLog

Private music project journal for iOS and macOS. Built with SwiftUI (multiplatform), backed by Supabase.

## Project Setup

### Prerequisites
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [SwiftLint](https://github.com/realm/SwiftLint): `brew install swiftlint`
- [xcpretty](https://github.com/xcpretty/xcpretty): `gem install xcpretty`

### Getting started
```bash
make generate   # generates WavLog.xcodeproj from project.yml
make open       # opens in Xcode
```

## Architecture

- **SwiftUI multiplatform** — shared codebase for iOS and macOS, #if os() conditionals for platform-specific UI
- **Supabase** — auth (Sign in with Apple), postgres DB, storage (audio files), realtime
- **Feature folders** — code organized by feature under Sources/WavLog/Features/

## Key Directories

- `Sources/WavLog/App/` — entry point, root navigation
- `Sources/WavLog/Features/` — feature modules (Auth, Projects, Comments, Profile)
- `Sources/WavLog/Models/` — Codable data models matching Supabase schema
- `Sources/WavLog/Supabase/` — shared Supabase client configuration
- `Resources/` — assets, colors, icons

## Environment

Supabase credentials go in a `Config.swift` file (gitignored) or via Xcode build settings. See `Sources/WavLog/Supabase/SupabaseClient.swift` for the expected constants.

## Database Schema

See `Docs/schema.sql` for the full Supabase schema. Key tables:
- `profiles` — user profiles (extends auth.users)
- `projects` — music projects with metadata
- `bounces` — audio file version history per project
- `comments` — threaded feedback on projects
- `project_collaborators` — project access control
- `invites` — invite codes for onboarding

## Makefile

```bash
make generate   # regenerate Xcode project
make build      # build for iOS simulator
make test       # run test suite
make lint       # SwiftLint
make lint-fix   # auto-fix lint issues
make open       # generate + open in Xcode
```
