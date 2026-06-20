-- Adds Music Understanding auto-analysis columns to projects.
-- See WavLog_PRD_v2.docx section 5.6.
-- Run manually in the Supabase SQL editor.

alter table projects
    add column if not exists detected_bpm integer,
    add column if not exists detected_key text,
    add column if not exists waveform_data jsonb,
    add column if not exists structure_data jsonb,
    add column if not exists instrument_data jsonb,
    add column if not exists loudness_data jsonb;
