-- +goose Up
-- Users & Auth
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    password_hash TEXT,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    is_guest BOOLEAN NOT NULL DEFAULT FALSE,
    guest_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trips
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEST NOT NULL,
    notes TEXT,
    start_date date,
);

CREATE TABLE trip_members (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'editor', -- owner | editor | viewer
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE trip_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,
    max_uses INT,
    use_count INT NOT NULL DEFAULT 0
);

-- Destinations
CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    notes TEXT,
    lat NUMERIC(9, 6),
    long NUMERIC(9, 6),
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Itinerary
CREATE TABLE itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    notes TEXT,
    lat NUMERIC(9, 6) NOT NULL,
    long NUMERIC(9, 6) NOT NULL,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Geocode cache
CREATE TABLE geocode_cache (
    query TEXT PRIMARY KEY,
    lat NUMERIC(9, 6),
    long NUMERIC(9, 6),
    name TEST NOT NULL,
    cahced_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
create index on trip_members (user_id);
create index on destinations (trip_id;
create index on itinerary_items (destination_id);
create index on refresh_tokens (user_id);
create index on users (is_guest, guest_expres_at) where is_guest = true;

-- +goose Down
drop table if exists geocode_cache;
drop table if exists itinerary_items;
drop table if exists destinations;
drop table if exists trip_invites;
drop table if exists trip_members;
drop table if exists trips;
drop table if exists refresh_tokens;
drop table if exists users;
