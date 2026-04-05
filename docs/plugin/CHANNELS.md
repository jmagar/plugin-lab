# Channels -- plugin-lab

plugin-lab does not use Claude Code channels.

## What channels are

Channels provide bidirectional messaging between a Claude Code plugin and external services (e.g., Discord, Slack, webhooks). They allow agents to receive messages from and send messages to external platforms.

## Why plugin-lab does not use channels

plugin-lab is a development toolkit, not a runtime service. It has no need for external messaging integration. The agents operate locally within Claude Code sessions, reading files and producing artifacts.

Plugins scaffolded by plugin-lab may choose to add channels if they integrate with messaging services. See the template documentation at `templates/docs/plugin/CHANNELS.md` for the channel definition pattern.
