#[derive(Debug, Clone)]
pub struct MyPluginClient {
    pub base_url: String,
    pub api_key: Option<String>,
}

impl MyPluginClient {
    pub fn new(base_url: String, api_key: Option<String>) -> Self {
        Self { base_url, api_key }
    }

    pub fn health(&self) -> String {
        format!("ok: {}", self.base_url)
    }
}
