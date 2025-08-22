use anyhow::Result;
use serde::{Deserialize, Serialize};
use gurt::prelude::*;

pub struct GurtCAClient {
    ca_url: String,
    gurt_client: GurtClient,
}

#[derive(Serialize, Deserialize)]
pub struct CertificateRequest {
    pub domain: String,
    pub csr: String,
    pub challenge_type: String,
}

#[derive(Serialize, Deserialize)]
pub struct Challenge {
    pub token: String,
    pub challenge_type: String,
    pub domain: String,
    pub verification_data: String,
}

#[derive(Serialize, Deserialize)]
pub struct Certificate {
    pub cert_pem: String,
    pub chain_pem: String,
    pub expires_at: chrono::DateTime<chrono::Utc>,
}

impl GurtCAClient {
    pub fn new(ca_url: String) -> Result<Self> {
        let gurt_client = GurtClient::new();
            
        Ok(Self {
            ca_url,
            gurt_client,
        })
    }
    
    pub async fn new_with_ca_discovery(ca_url: String) -> Result<Self> {
        println!("🔍 Attempting to connect with system CA trust store...");
        
        let test_client = Self::new(ca_url.clone())?;
        
        match test_client.test_connection().await {
            Ok(_) => {
                println!("✅ Connection successful with system CA trust store");
                return Ok(test_client);
            }
            Err(e) => {
                if e.to_string().contains("UnknownIssuer") {
                    anyhow::bail!("Custom CA certificate required - server not trusted by system")
                } else {
                    return Err(e);
                }
            }
        }
    }
    
    async fn test_connection(&self) -> Result<()> {
        // Try a simple request to test if connection works
        let _response = self.gurt_client
            .get(&format!("{}/ca/root", self.ca_url))
            .await?;
        Ok(())
    }
    
    pub async fn fetch_ca_certificate(&self) -> Result<String> {
        let response = self.gurt_client
            .get(&format!("{}/ca/root", self.ca_url))
            .await?;
            
        if response.is_success() {
            let ca_cert = response.text()?;
            // Basic validation that this looks like a PEM certificate
            if ca_cert.contains("BEGIN CERTIFICATE") && ca_cert.contains("END CERTIFICATE") {
                Ok(ca_cert)
            } else {
                anyhow::bail!("Invalid CA certificate format received")
            }
        } else {
            anyhow::bail!("Failed to fetch CA certificate: HTTP {}", response.status_code)
        }
    }
    
    pub async fn verify_domain_exists(&self, domain: &str) -> Result<bool> {
        let response = self.gurt_client
            .get(&format!("{}/verify-ownership/{}", self.ca_url, domain))
            .await?;
            
        if response.is_success() {
            let result: serde_json::Value = serde_json::from_slice(&response.body)?;
            Ok(result["exists"].as_bool().unwrap_or(false))
        } else {
            Ok(false)
        }
    }
    
    pub async fn request_certificate(&self, domain: &str, csr: &str) -> Result<Challenge> {
        let request = CertificateRequest {
            domain: domain.to_string(),
            csr: csr.to_string(),
            challenge_type: "dns".to_string(),
        };
        
        let response = self.gurt_client
            .post_json(&format!("{}/ca/request-certificate", self.ca_url), &request)
            .await?;
            
        if response.is_success() {
            let challenge: Challenge = serde_json::from_slice(&response.body)?;
            Ok(challenge)
        } else {
            let error_text = response.text()?;
            anyhow::bail!("Certificate request failed: {}", error_text)
        }
    }
    
    pub async fn poll_certificate(&self, challenge_token: &str) -> Result<Certificate> {
        for _ in 0..60 {
            let response = self.gurt_client
                .get(&format!("{}/ca/certificate/{}", self.ca_url, challenge_token))
                .await?;
                
            if response.is_success() {
                let body_text = response.text()?;
                if body_text.trim().is_empty() {
                    // Empty response, certificate not ready yet
                    tokio::time::sleep(std::time::Duration::from_secs(5)).await;
                    continue;
                }
                let cert: Certificate = serde_json::from_str(&body_text)?;
                return Ok(cert);
            } else if response.status_code == 202 {
                tokio::time::sleep(std::time::Duration::from_secs(5)).await;
                continue;
            } else {
                let error_text = response.text()?;
                anyhow::bail!("Certificate polling failed: {}", error_text);
            }
        }
        
        anyhow::bail!("Certificate issuance timed out")
    }
    
    pub async fn fetch_ca_certificate(&self) -> Result<String> {
        if let Ok(ca_cert) = self.fetch_ca_via_http().await {
            return Ok(ca_cert);
        }
        
        let response = self.gurt_client
            .get(&format!("{}/ca/root", self.ca_url))
            .await?;
            
        if response.is_success() {
            let ca_cert = response.text()?;
            if ca_cert.contains("BEGIN CERTIFICATE") && ca_cert.contains("END CERTIFICATE") {
                Ok(ca_cert)
            } else {
                anyhow::bail!("Invalid CA certificate format received")
            }
        } else {
            anyhow::bail!("Failed to fetch CA certificate: HTTP {}", response.status_code)
        }
    }
    
    async fn fetch_ca_via_http(&self) -> Result<String> {
        let http_url = self.ca_url
            .replace("gurt://", "http://")
            .replace(":8877", ":8876");
        
        let client = reqwest::Client::new();
        let response = client
            .get(&format!("{}/ca/root", http_url))
            .send()
            .await?;
            
        if response.status().is_success() {
            let ca_cert = response.text().await?;
            if ca_cert.contains("BEGIN CERTIFICATE") && ca_cert.contains("END CERTIFICATE") {
                println!("✅ Fetched CA certificate via HTTP bootstrap");
                Ok(ca_cert)
            } else {
                anyhow::bail!("Invalid CA certificate format received via HTTP")
            }
        } else {
            anyhow::bail!("HTTP bootstrap failed: {}", response.status())
        }
    }
}