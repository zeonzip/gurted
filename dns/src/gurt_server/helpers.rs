use gurt::prelude::*;

use std::net::IpAddr;

pub fn validate_ip(domain: &super::models::Domain) -> Result<()> {
    if domain.ip.parse::<IpAddr>().is_err() {
        return Err(GurtError::invalid_message("Invalid IP address"));
    }
    
    Ok(())
}

pub fn deserialize_lowercase<'de, D>(deserializer: D) -> std::result::Result<String, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use serde::Deserialize;
    let s = String::deserialize(deserializer)?;
    Ok(s.to_lowercase())
}