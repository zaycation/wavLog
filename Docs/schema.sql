-- WavLog Supabase Schema
-- Run this in Supabase SQL editor to bootstrap the database.

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles (extends auth.users)
create table profiles (
    id          uuid references auth.users(id) on delete cascade primary key,
    display_name text not null,
    avatar_url  text,
    created_at  timestamptz not null default now()
);
alter table profiles enable row level security;
create policy "Users can view all profiles" on profiles for select using (true);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Auto-create profile on sign up
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
    insert into profiles (id, display_name)
    values (new.id, coalesce(new.raw_user_meta_data->>'full_name', 'New User'));
    return new;
end;
$$;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure handle_new_user();

-- Invites
create table invites (
    id          uuid primary key default uuid_generate_v4(),
    code        text unique not null,
    created_by  uuid references profiles(id) not null,
    used_by     uuid references profiles(id),
    used_at     timestamptz,
    created_at  timestamptz not null default now()
);
alter table invites enable row level security;
create policy "Users can view their own invites" on invites for select using (auth.uid() = created_by);

-- Projects
create type project_status as enum ('wip', 'shared', 'complete');

create table projects (
    id              uuid primary key default uuid_generate_v4(),
    owner_id        uuid references profiles(id) not null,
    title           text not null,
    bpm             integer,
    key             text,
    genre           text,
    influences      text,
    bandlab_url     text,
    status          project_status not null default 'wip',
    is_archived     boolean not null default false,
    lyrics_notes    text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);
alter table projects enable row level security;

-- Project collaborators
create table project_collaborators (
    project_id  uuid references projects(id) on delete cascade not null,
    user_id     uuid references profiles(id) on delete cascade not null,
    invited_by  uuid references profiles(id) not null,
    invited_at  timestamptz not null default now(),
    primary key (project_id, user_id)
);
alter table project_collaborators enable row level security;

-- RLS helpers
create or replace function is_project_member(project_id uuid)
returns boolean language sql security definer as $$
    select exists (
        select 1 from projects where id = project_id and owner_id = auth.uid()
        union
        select 1 from project_collaborators where project_id = project_id and user_id = auth.uid()
    );
$$;

create policy "Members can view projects" on projects for select
    using (is_project_member(id));
create policy "Owner can insert projects" on projects for insert
    with check (auth.uid() = owner_id);
create policy "Members can update projects" on projects for update
    using (is_project_member(id));
create policy "Owner can delete projects" on projects for delete
    using (auth.uid() = owner_id);

-- Bounces (audio version history)
create table bounces (
    id              uuid primary key default uuid_generate_v4(),
    project_id      uuid references projects(id) on delete cascade not null,
    uploader_id     uuid references profiles(id) not null,
    storage_path    text not null,
    version_note    text,
    created_at      timestamptz not null default now()
);
alter table bounces enable row level security;
create policy "Members can view bounces" on bounces for select
    using (is_project_member(project_id));
create policy "Members can insert bounces" on bounces for insert
    with check (is_project_member(project_id));
create policy "Uploader can delete own bounces" on bounces for delete
    using (auth.uid() = uploader_id);

-- Comments
create table comments (
    id          uuid primary key default uuid_generate_v4(),
    project_id  uuid references projects(id) on delete cascade not null,
    author_id   uuid references profiles(id) not null,
    parent_id   uuid references comments(id),
    body        text not null,
    audio_path  text,
    is_resolved boolean not null default false,
    created_at  timestamptz not null default now()
);
alter table comments enable row level security;
create policy "Members can view comments" on comments for select
    using (is_project_member(project_id));
create policy "Members can insert comments" on comments for insert
    with check (is_project_member(project_id) and auth.uid() = author_id);
create policy "Author can update own comment" on comments for update
    using (auth.uid() = author_id);

-- Storage bucket for audio files
insert into storage.buckets (id, name, public)
values ('audio', 'audio', false)
on conflict do nothing;

create policy "Members can upload audio" on storage.objects for insert
    with check (bucket_id = 'audio' and auth.role() = 'authenticated');
create policy "Members can read audio" on storage.objects for select
    using (bucket_id = 'audio' and auth.role() = 'authenticated');
create policy "Uploader can delete audio" on storage.objects for delete
    using (bucket_id = 'audio' and auth.uid()::text = (storage.foldername(name))[1]);
