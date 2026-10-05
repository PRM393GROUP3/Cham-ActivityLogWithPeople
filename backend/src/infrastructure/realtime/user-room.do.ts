import { DurableObject } from "cloudflare:workers";

/**
 * One instance per user, holding that user's open WebSockets (one per device/tab).
 * Uses the Hibernation API so idle connections don't bill duration.
 */
export class UserRoom extends DurableObject<Env> {
  override async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket upgrade", { status: 426 });
    }
    const { 0: client, 1: server } = new WebSocketPair();
    this.ctx.acceptWebSocket(server);
    return new Response(null, { status: 101, webSocket: client });
  }

  /** Called via RPC from the Worker after a successful write. */
  send(message: unknown): void {
    const payload = JSON.stringify(message);
    for (const ws of this.ctx.getWebSockets()) {
      try {
        ws.send(payload);
      } catch {
        // Socket already closing; the runtime will clean it up.
      }
    }
  }

  override webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): void {
    if (message === "ping") ws.send("pong");
  }

  override webSocketClose(ws: WebSocket, code: number): void {
    ws.close(code, "closing");
  }
}
