## Session 1 — 2026-09-17

**Strategy:** Preserve the original 24.6-second Theora picture and original audio, then mix in the player's new menu BGM at approximately -6 dB relative to its source. Keep the original video untouched and switch the game to the separately mixed OGV.
**Decisions:** Theora video stream copied without re-encoding; stereo Vorbis audio remixed. A quiet, time-synchronized copy of the same BGM runs in the game's audio manager during the video and is handed off to the menu, avoiding a restart when the video ends or is skipped.
**Verification:** FFprobe confirms 960×540 Theora, 44.1 kHz stereo Vorbis, 24.6 seconds. Godot playback and skip/natural-end tests passed. No subtitles, cuts, visual overlays, or grading changes.
