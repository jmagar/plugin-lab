# Service Credentials Guide

Per-service credential reference for the homelab-core setup wizard. For each service, this lists the environment variable names, where to find the credential value, and the expected URL format.

---

## ZFS

**No credentials required.** ZFS commands run locally via the CLI (`zpool`, `zfs`). Skip this service during credential collection in Step 2 — no `.env` entries are needed.

---

## Infrastructure

### Unraid

Variables: `UNRAID_SERVER1_NAME`, `UNRAID_SERVER1_URL`, `UNRAID_SERVER1_API_KEY`
Optional second server: `UNRAID_SERVER2_NAME`, `UNRAID_SERVER2_URL`, `UNRAID_SERVER2_API_KEY`

- **URL format**: `https://your-unraid-ip/graphql`
- **API key**: Unraid UI → Settings → Management Access → API Keys → Create. Viewer role is sufficient for read-only health checks; Admin role required for write operations.
- **Name**: A display label for the server (e.g., `tower`, `nas2`). Used in health check output.
- Supports two servers. Skip `SERVER2_*` variables if you only have one Unraid host.

### UniFi

Variables: `UNIFI_URL`, `UNIFI_USERNAME`, `UNIFI_PASSWORD`, `UNIFI_SITE`

- **URL format**: `https://your-unifi-controller-ip` (no trailing slash, no port unless non-standard)
- **Username/Password**: Local controller credentials (not UniFi account SSO)
- **Site**: Usually `default`. Check the URL in your UniFi dashboard — the site name appears after `/manage/site/`.

### Tailscale

Variables: `TAILSCALE_API_KEY`, `TAILSCALE_TAILNET`

- **API key**: [tailscale.com/admin/settings/keys](https://tailscale.com/admin/settings/keys) → Generate access token
- **Tailnet**: Your tailnet name. For personal accounts use `-`. For organization accounts it looks like `example.com`.

---

## Media

### Plex

Variables: `PLEX_URL`, `PLEX_TOKEN`

- **URL format**: `https://your-plex-ip:32400` (include the port; no trailing slash)
- **Token**: Open Plex Web → click any media item → Get Info → View XML. The `X-Plex-Token` value appears in the URL. Alternatively, sign in at [plex.tv/claim](https://plex.tv/claim) and use the claim token (short-lived; prefer the XML method for a persistent token).

### Radarr

Variables: `RADARR_URL`, `RADARR_API_KEY`

- **URL format**: `https://your-radarr-ip:7878`
- **API key**: Radarr UI → Settings → General → Security → API Key

### Sonarr

Variables: `SONARR_URL`, `SONARR_API_KEY`

- **URL format**: `https://your-sonarr-ip:8989`
- **API key**: Sonarr UI → Settings → General → Security → API Key

### Overseerr

Variables: `OVERSEERR_URL`, `OVERSEERR_API_KEY`

- **URL format**: `https://your-overseerr-ip:5055`
- **API key**: Overseerr UI → Settings → General → API Key

### Prowlarr

Variables: `PROWLARR_URL`, `PROWLARR_API_KEY`

- **URL format**: `https://your-prowlarr-ip:9696`
- **API key**: Prowlarr UI → Settings → General → Security → API Key

### Tautulli

Variables: `TAUTULLI_URL`, `TAUTULLI_API_KEY`

- **URL format**: `https://your-tautulli-ip:8181`
- **API key**: Tautulli UI → Settings → Web Interface → API Key

---

## Downloads

### qBittorrent

Variables: `QBITTORRENT_URL`, `QBITTORRENT_USERNAME`, `QBITTORRENT_PASSWORD`

- **URL format**: `https://your-qbittorrent-ip:8080` (the WebUI URL)
- **Username/Password**: The credentials you set in qBittorrent WebUI → Tools → Options → Web UI → Authentication

### SABnzbd

Variables: `SABNZBD_URL`, `SABNZBD_API_KEY`

- **URL format**: `https://your-sabnzbd-ip:8080`
- **API key**: SABnzbd UI → Config → General → Security → API Key (not the NZB Key)

---

## Utilities

### Gotify

Variables: `GOTIFY_URL`, `GOTIFY_TOKEN`

- **URL format**: `https://your-gotify-ip` (no trailing slash)
- **Token**: Gotify UI → Apps → Create new application → copy the token. This is an *application* token, used for sending messages. For management operations (listing apps, clients), you need a *client* token from Gotify UI → Clients.

### Linkding

Variables: `LINKDING_URL`, `LINKDING_API_KEY`

- **URL format**: `https://your-linkding-ip:9090`
- **API key**: Linkding UI → Settings → REST API → API Token

### Memos

Variables: `MEMOS_URL`, `MEMOS_API_TOKEN`

- **URL format**: `https://your-memos-ip:5230`
- **Token**: Memos UI → Settings (gear icon) → My Account → API Tokens → Create

### ByteStash

Variables: `BYTESTASH_URL`, `BYTESTASH_API_KEY`

- **URL format**: `https://your-bytestash-ip`
- **API key**: ByteStash UI → Settings → API → Generate API Key

### Paperless-ngx

Variables: `PAPERLESS_URL`, `PAPERLESS_API_TOKEN`

- **URL format**: `https://your-paperless-ip:8000`
- **Token**: Paperless-ngx Admin UI → Auth Tokens → Add token (assign to your user account)

### Radicale

Variables: `RADICALE_URL`, `RADICALE_USERNAME`, `RADICALE_PASSWORD`

- **URL format**: `https://your-radicale-ip:5232`
- **Username/Password**: The credentials configured in your Radicale `users` file or htpasswd file. These are the same credentials used by CalDAV/CardDAV clients.

---

## Notes

- All URLs should use HTTPS in production. HTTP is accepted for local-only setups where TLS is not configured.
- Ports shown above are defaults. If you've changed the port in your service configuration, use your actual port.
- After writing any credential, the setup wizard sets `chmod 600 ~/.claude-homelab/.env` to restrict access to the file owner.
