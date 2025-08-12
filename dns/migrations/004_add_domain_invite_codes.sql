-- Add domain_invite_codes field to users table
ALTER TABLE users ADD COLUMN domain_invite_codes INTEGER DEFAULT 3;

-- Create domain invite codes table for domain-specific invites
CREATE TABLE IF NOT EXISTS domain_invite_codes (
    id SERIAL PRIMARY KEY,
    code VARCHAR(32) UNIQUE NOT NULL,
    created_by INTEGER REFERENCES users(id),
    used_by INTEGER REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMPTZ
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_domain_invite_codes_code ON domain_invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_domain_invite_codes_created_by ON domain_invite_codes(created_by);
CREATE INDEX IF NOT EXISTS idx_domain_invite_codes_used_by ON domain_invite_codes(used_by);