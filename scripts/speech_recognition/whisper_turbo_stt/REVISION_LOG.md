# Whisper Turbo STT Revision Log

| Date | Knob | Old Value | New Value | Reason for Change |
| :--- | :--- | :--- | :--- | :--- |
| 2026-02-13 | `post_speech_silence_duration` | 0.7 | 0.65 | Snappier transcription after speaking. |
| 2026-02-13 | `silero_sensitivity` | 0.2 | 0.4 | Eliminate ghost "Thank you" and headset leakage. |
| 2026-02-13 | `min_gap_between_recordings` | 0.05 | 0.0 | Remove "blind spot" gap between sentences. |
| 2026-02-13 | `beam_size` | 5 (default) | 1 | Maximize speed and eliminate missing words. |
| 2026-02-16 | `post_speech_silence_duration` | 0.65 | 0.7 | Restore patience for thinking mid-sentence. |
| 2026-02-16 | `beam_size` | 1 | 5 | Restore accuracy and logic context. |
| 2026-02-16 | `silero_sensitivity` | 0.4 | 0.2 | Fix missing first word; increase responsiveness. |
