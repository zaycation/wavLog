# WavLog

A private, invite-only music project journal for producers and artists. Log beats, track creative lifecycles, and collaborate with a small trusted circle — without the noise of a social platform.

Think Linear for music.

## What it does

- Log music projects with metadata: title, BPM, key, genre, influences, BandLab links
- Upload bounces (.wav / .m4a) with version history, Git-commit style
- Threaded feedback comments on every project, with audio attachments
- Invite-only access — Clubhouse-style — to keep the circle tight
- Activity chart on your profile showing creative output over time
- Three project views: rolodex cards (default), list, and grid
- Background audio playback so you can listen while doing other things
- iOS + macOS via shared SwiftUI codebase

## Tech stack

- **Frontend**: SwiftUI (iOS 17+, macOS 14+)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Auth**: Sign in with Apple, invite-gated
- **Project management**: XcodeGen (`project.yml` → `.xcodeproj`)
- **Future**: Apple Music Understanding framework (iOS 27 / macOS 27 Golden Gate) for on-device BPM, key, structure, and instrument analysis

## Project structure
