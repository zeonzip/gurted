use super::helpers::deserialize_lowercase;
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, types::chrono::{DateTime, Utc}};
use chrono;

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
}

#[derive(Debug, Serialize, Deserialize)]
pub(crate) struct UpdateDomain {
    pub(crate) ip: String,
}

#[derive(Serialize)]
pub(crate) struct Error {
    pub(crate) msg: &'static str,
    pub(crate) error: String,
}

#[derive(Serialize)]
pub(crate) struct Ratelimit {
    pub(crate) msg: String,
    pub(crate) error: &'static str,
    pub(crate) after: u64,
}

#[derive(Deserialize)]
pub(crate) struct PaginationParams {
    #[serde(alias = "p", alias = "doc")]
    pub(crate) page: Option<u32>,
    #[serde(alias = "s", alias = "size", alias = "l", alias = "limit")]
    pub(crate) page_size: Option<u32>,
}

#[derive(Serialize)]
pub(crate) struct PaginationResponse {
    pub(crate) domains: Vec<ResponseDomain>,
    pub(crate) page: u32,
    pub(crate) limit: u32,
}

#[derive(Deserialize)]
pub(crate) struct DomainQuery {
    pub(crate) name: String,
    pub(crate) tld: Option<String>,
}

#[derive(Serialize)]
pub(crate) struct DomainList {
    pub(crate) domain: String,
    pub(crate) taken: bool,
}
