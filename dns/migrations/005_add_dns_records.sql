CREATE TABLE dns_records (
    id SERIAL PRIMARY KEY,
    domain_id INTEGER NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
    record_type VARCHAR(10) NOT NULL CHECK (record_type IN ('A', 'AAAA', 'CNAME', 'TXT', 'MX', 'NS', 'SRV')),
    name VARCHAR(255) NOT NULL DEFAULT '@', -- @ for root, or subdomain name
    value VARCHAR(1000) NOT NULL,
    ttl INTEGER DEFAULT 3600,
    priority INTEGER, -- For MX records
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_dns_records_domain_type ON dns_records(domain_id, record_type);
CREATE INDEX idx_dns_records_name ON dns_records(name);

INSERT INTO dns_records (domain_id, record_type, name, value, ttl)
SELECT id, 'A', '@', ip, 3600 
FROM domains 
WHERE status = 'approved';

INSERT INTO dns_records (domain_id, record_type, name, value, ttl, priority)
SELECT id, 'SRV', '_gurt._tcp', '0 5 4878 @', 3600, 0
FROM domains 
WHERE status = 'approved';