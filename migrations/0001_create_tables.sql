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
    name TEXT NOT NULL,
    notes TEXT,
    visibility TEXT NOT NULL DEFAULT 'private', -- private | public
    start_date DATE,
    end_date DATE,
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trip_members (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'editor', -- owner | editor | viewer
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE trip_code_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    created_by UUID NOT NULL REFERENCES users (id),
    role TEXT NOT NULL DEFAULT 'viewer', -- viewer | editor
    max_uses INT,
    use_count INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trip_direct_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users (id),
    role TEXT NOT NULL DEFAULT 'viewer', -- viewer | editor
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (trip_id, user_id)
);

CREATE TABLE trip_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'editor', -- viewer | editor
    status TEXT NOT NULL DEFAULT 'pending', -- pending | accepted | rejected
    resolved_by UUID REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    UNIQUE (trip_id, user_id)
);

-- Destinations
CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    notes TEXT,
    lat NUMERIC(9, 6),
    long NUMERIC(9, 6),
    position INT NOT NULL,
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
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    position INT NOT NULL,
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Legs
CREATE TABLE legs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    from_destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    to_destination_id UUID NOT NULL REFERENCES destinations (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    notes TEXT,
    distance NUMERIC(10, 2),
    cost NUMERIC(10, 2),
    created_by UUID NOT NULL REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (trip_id, from_destination_id, to_destination_id),
    CHECK (from_destination_id <> to_destination_id)
);

-- Geocode Cache
CREATE TABLE geocode_cache (
    query TEXT PRIMARY KEY,
    lat NUMERIC(9, 6) NOT NULL,
    long NUMERIC(9, 6) NOT NULL,
    name TEXT NOT NULL,
    cached_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX ON trip_access_requests (trip_id);

CREATE INDEX ON trip_direct_invites (trip_id);

CREATE INDEX ON trip_direct_invites (user_id);

CREATE INDEX ON trip_code_invites (trip_id);

CREATE INDEX ON legs (trip_id);

CREATE INDEX ON trip_members (user_id);

CREATE INDEX ON destinations (trip_id);

CREATE INDEX ON itinerary_items (destination_id);

CREATE INDEX ON refresh_tokens (user_id);

CREATE INDEX ON users (is_guest, guest_expires_at)
WHERE
    is_guest = TRUE;

-- +goose Down
DROP TABLE IF EXISTS trip_access_requests;

DROP TABLE IF EXISTS trip_direct_invites;

DROP TABLE IF EXISTS trip_code_invites;

DROP TABLE IF EXISTS legs;

DROP TABLE IF EXISTS geocode_cache;

DROP TABLE IF EXISTS itinerary_items;

DROP TABLE IF EXISTS destinations;

DROP TABLE IF EXISTS trip_members;

DROP TABLE IF EXISTS trips;

DROP TABLE IF EXISTS refresh_tokens;

DROP TABLE IF EXISTS users;
