use serenity::async_trait;
use serenity::all::*;
use sqlx::PgPool;

pub struct DiscordBot {
    pub pool: PgPool,
}

#[derive(Debug)]
pub struct DomainRegistration {
    pub id: i32,
    pub domain_name: String,
    pub tld: String,
    pub ip: String,
    pub user_id: i32,
    pub username: String,
}

pub struct BotHandler {
    pub pool: PgPool,
}

#[async_trait]
impl EventHandler for BotHandler {
    async fn ready(&self, _: Context, ready: Ready) {
        log::info!("Discord bot {} is connected!", ready.user.name);
    }

    async fn interaction_create(&self, ctx: Context, interaction: Interaction) {
        match interaction {
            Interaction::Component(component) => {
                let custom_id = &component.data.custom_id;
                
                if custom_id.starts_with("approve_") {
                    let domain_id: i32 = match custom_id.strip_prefix("approve_").unwrap().parse() {
                        Ok(id) => id,
                        Err(_) => {
                            log::error!("Invalid domain ID in approve button");
                            return;
                        }
                    };
                    
                    // Update domain status to approved
                    match sqlx::query("UPDATE domains SET status = 'approved' WHERE id = $1")
                        .bind(domain_id)
                        .execute(&self.pool)
                        .await
                    {
                        Ok(_) => {
                            let response = CreateInteractionResponse::Message(
                                CreateInteractionResponseMessage::new()
                                    .content("✅ Domain approved!")
                                    .ephemeral(true)
                            );
                            
                            if let Err(e) = component.create_response(&ctx.http, response).await {
                                log::error!("Error responding to interaction: {}", e);
                            }
                        }
                        Err(e) => {
                            log::error!("Error approving domain: {}", e);
                            let response = CreateInteractionResponse::Message(
                                CreateInteractionResponseMessage::new()
                                    .content("❌ Error approving domain")
                                    .ephemeral(true)
                            );
                            let _ = component.create_response(&ctx.http, response).await;
                        }
                    }
                } else if custom_id.starts_with("deny_") {
                    let domain_id = custom_id.strip_prefix("deny_").unwrap();
                    
                    // Create modal for denial reason
                    let modal = CreateModal::new(
                        format!("deny_modal_{}", domain_id),
                        "Deny Domain Registration"
                    )
                    .components(vec![
                        CreateActionRow::InputText(
                            CreateInputText::new(
                                InputTextStyle::Paragraph,
                                "Reason",
                                "reason"
                            )
                            .placeholder("Please provide a reason for denying this domain registration")
                            .required(true)
                        )
                    ]);

                    let response = CreateInteractionResponse::Modal(modal);

                    if let Err(e) = component.create_response(&ctx.http, response).await {
                        log::error!("Error showing modal: {}", e);
                    }
                }
            }
            Interaction::Modal(modal_submit) => {
                if modal_submit.data.custom_id.starts_with("deny_modal_") {
                    let domain_id: i32 = match modal_submit.data.custom_id.strip_prefix("deny_modal_").unwrap().parse() {
                        Ok(id) => id,
                        Err(_) => {
                            log::error!("Invalid domain ID in deny modal");
                            return;
                        }
                    };
                    
                    // Get the reason from modal input
                    let reason = modal_submit.data.components.get(0)
                        .and_then(|row| row.components.get(0))
                        .and_then(|component| {
                            if let ActionRowComponent::InputText(input) = component {
                                input.value.as_ref().map(|v| v.as_str())
                            } else {
                                None
                            }
                        })
                        .unwrap_or("No reason provided");
                    
                    // Update domain status to denied with reason
                    match sqlx::query("UPDATE domains SET status = 'denied', denial_reason = $1 WHERE id = $2")
                        .bind(reason)
                        .bind(domain_id)
                        .execute(&self.pool)
                        .await
                    {
                        Ok(_) => {
                            let response = CreateInteractionResponse::Message(
                                CreateInteractionResponseMessage::new()
                                    .content("❌ Domain denied!")
                                    .ephemeral(true)
                            );
                            
                            if let Err(e) = modal_submit.create_response(&ctx.http, response).await {
                                log::error!("Error responding to modal: {}", e);
                            }
                        }
                        Err(e) => {
                            log::error!("Error denying domain: {}", e);
                            let response = CreateInteractionResponse::Message(
                                CreateInteractionResponseMessage::new()
                                    .content("❌ Error denying domain")
                                    .ephemeral(true)
                            );
                            let _ = modal_submit.create_response(&ctx.http, response).await;
                        }
                    }
                }
            }
            _ => {
                // Handle other interaction types if needed
                log::debug!("Unhandled interaction type: {:?}", interaction.kind());
            }
        }
    }
}

pub async fn send_domain_approval_request(
    channel_id: u64,
    registration: DomainRegistration,
    bot_token: &str,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let http = serenity::http::Http::new(bot_token);
    
    let embed = CreateEmbed::new()
        .title("New Domain Registration")
        .field("Domain", format!("{}.{}", registration.domain_name, registration.tld), true)
        .field("IP", &registration.ip, true)
        .field("User", &registration.username, true)
        .field("User ID", registration.user_id.to_string(), true)
        .color(0x00ff00);

    let approve_button = CreateButton::new(format!("approve_{}", registration.id))
        .style(ButtonStyle::Success)
        .label("✅ Approve");
        
    let deny_button = CreateButton::new(format!("deny_{}", registration.id))
        .style(ButtonStyle::Danger)
        .label("❌ Deny");

    let action_row = CreateActionRow::Buttons(vec![approve_button, deny_button]);

    let message = CreateMessage::new()
        .embed(embed)
        .components(vec![action_row]);

    let channel_id = ChannelId::new(channel_id);
    channel_id.send_message(&http, message).await?;
    
    Ok(())
}

pub async fn start_discord_bot(token: String, pool: PgPool) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let intents = GatewayIntents::GUILD_MESSAGES | GatewayIntents::MESSAGE_CONTENT;
    
    let mut client = Client::builder(&token, intents)
        .event_handler(BotHandler { pool })
        .await?;

    tokio::spawn(async move {
        if let Err(e) = client.start().await {
            log::error!("Discord bot error: {}", e);
        }
    });

    Ok(())
}