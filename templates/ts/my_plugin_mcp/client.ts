export class MyPluginClient {
  constructor(
    readonly baseUrl: string,
    readonly apiKey?: string,
  ) {}

  async health(): Promise<{ status: string; baseUrl: string }> {
    return { status: "ok", baseUrl: this.baseUrl };
  }
}
