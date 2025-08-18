use super::helpers::deserialize_lowercase;
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, types::chrono::{DateTime, Utc}};

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct Domain {
    #[serde(skip_deserializing)]
    pub(crate) id: Option<i32>,
    pub(crate) ip: String,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) tld: String,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) name: String,
    #[serde(skip_deserializing)]
    pub(crate) user_id: Option<i32>,
    #[serde(skip_deserializing)]
    pub(crate) status: Option<String>,
    #[serde(skip_deserializing)]
    pub(crate) denial_reason: Option<String>,
    #[serde(skip_deserializing)]
    pub(crate) created_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct DnsRecord {
    #[serde(skip_deserializing)]
    pub(crate) id: Option<i32>,
    pub(crate) domain_id: i32,
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) record_type: String, // A, AAAA, CNAME, TXT, MX, NS
    #[serde(deserialize_with = "deserialize_lowercase")]
    pub(crate) name: String,        // subdomain or @ for root
    pub(crate) value: String,       // IP, domain, text value, etc.
    pub(crate) ttl: Option<i32>,    // Time to live in seconds
    pub(crate) priority: Option<i32>, // For MX records
    #[serde(skip_deserializing)]
    pub(crate) created_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct User {
    pub(crate) id: i32,
    pub(crate) username: String,
    pub(crate) password_hash: String,
    pub(crate) registrations_remaining: i32,
    pub(crate) domain_invite_codes: i32,
    pub(crate) created_at: DateTime<Utc>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct InviteCode {
    pub(crate) id: i32,
    pub(crate) code: String,
    pub(crate) created_by: Option<i32>,
    pub(crate) used_by: Option<i32>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) used_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Deserialize, Serialize, FromRow)]
pub struct DomainInviteCode {
    pub(crate) id: i32,
    pub(crate) code: String,
    pub(crate) created_by: Option<i32>,
    pub(crate) used_by: Option<i32>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) used_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
pub(crate) struct ResponseDomain {
    pub(crate) tld: String,
    pub(crate) ip: String,
    pub(crate) name: String,
    pub(crate) records: Option<Vec<ResponseDnsRecord>>,
}

#[derive(Debug, Serialize)]
pub(crate) struct ResponseDnsRecord {
    pub(crate) record_type: String,
    pub(crate) name: String,
    pub(crate) value: String,
    pub(crate) ttl: Option<i32>,
    pub(crate) priority: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub(crate) struct UpdateDomain {
    pub(crate) ip: String,
}

#[derive(Serialize)]
pub(crate) struct PaginationResponse {
    pub(crate) domains: Vec<ResponseDomain>,
    pub(crate) page: u32,
    pub(crate) limit: u32,
}

#[derive(Serialize)]
pub(crate) struct DomainList {
    pub(crate) domain: String,
    pub(crate) taken: bool,
}
