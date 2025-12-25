(function liveReloadConnect() {
  if (location.hostname !== "localhost" && location.hostname !== "127.0.0.1")
    return;

  const host = location.hostname;
  const port = 35729;

  const wsUrl = `ws://${host}:${port}/livereload`;
  let ws;

  function connect() {
    ws = new WebSocket(wsUrl);

    ws.onmessage = function (event) {
      try {
        const data = JSON.parse(event.data);
        if (data && data.command === "reload") {
          console.log("[LiveReload] Reloading page...");
          location.reload();
        }
      } catch (e) {
        // bỏ qua non-json messages
      }
    };

    ws.onclose = function () {
      console.log("[LiveReload] Disconnected. Reconnecting in 2s...");
      setTimeout(connect, 2000);
    };

    ws.onerror = function () {
      ws.close();
    };
  }

  connect();
})();
