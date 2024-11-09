const MiniBeacon = (function() {
  const config = {};
  const send = (eventType) => {
    const headers = { type: "application/json" };
    const body = { ...config };

    if (eventType)
      body.ev = eventType;

    const blob = new Blob([JSON.stringify(body)], headers);

    if (navigator.sendBeacon) {
      navigator.sendBeacon("http://localhost:3000/v1/beacons", blob);
    } else {
      // fallback to load an <img> element?
    }
  }

  return {
    setup(script) {
      if (!script) return;

      config.pid = script.dataset.propertyId;

      if (!config.pid)
        console.debug("MiniBeacon: No data-property-id on <script> tag");
    },

    emitPageView: () => {
      if (!config.pid) return;

      send("view");
    }
  };
}());

MiniBeacon.setup(document.currentScript);
MiniBeacon.emitPageView();
