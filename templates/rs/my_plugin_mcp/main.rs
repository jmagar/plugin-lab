mod client;

use anyhow::Result;
use client::MyPluginClient;

fn main() -> Result<()> {
    let base_url = std::env::var("MY_SERVICE_URL").unwrap_or_default();
    let api_key = std::env::var("MY_SERVICE_API_KEY").ok();
    let transport = std::env::var("MY_SERVICE_MCP_TRANSPORT").unwrap_or_else(|_| "http".to_string());

    let client = MyPluginClient::new(base_url, api_key);
    println!(
        "my-plugin-mcp scaffold entrypoint: transport={}, health={}",
        transport,
        client.health()
    );

    Ok(())
}
