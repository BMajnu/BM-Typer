BM-Typer - Android startup polish, mobile action access, and in-app update flow

Task Overview:

## Phase 1 - 2026-04-20
- [x] Split startup into critical boot and deferred background initialization
- [x] Remove the recurring in-app loading gate from normal app launches
- [x] Replace Android white/custom loading screen with a branded native splash using the BM Typer logo

## Phase 2 - 2026-04-20
- [x] Improve mobile tutor navigation so settings, profile, notifications, and update actions are easy to access
- [x] Add mobile-friendly quick actions in the tutor header and lesson drawer
- [x] Adapt slide-over panels that are desktop-oriented so they behave properly on mobile

## Phase 3 - 2026-04-20
- [x] Add an Android in-app update service that can download the release APK from the configured direct APK URL
- [x] Open the downloaded APK installer from inside the app and keep external-link fallback for non-APK targets
- [x] Update the auto-check and manual check UI so Android users can directly download/install updates from the app

## Phase 4 - 2026-04-20
- [x] Run targeted tests and static checks for the startup/update changes
- [x] Rebuild the Android release APK
- [ ] Run `MagicInput.py` after the implementation pass
