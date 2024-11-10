const MiniBeacon = (function() {
  // TODO: Add "ref" parameter for additional attribution
  const QS_KEY_NAMES = [
    "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"
  ];

  let propertyId, server;
  let configured = false;

  const locationQueryString = () => {
    const locParams = new URLSearchParams(location.search);
    const qs = new URLSearchParams();

    for (const [key, val] of locParams.entries()) {
      if (QS_KEY_NAMES.includes(key)) {
        qs.append(key, val);
      }
    }

    return qs.toString();
  }

  const getRandom = (length) => {
    if (window.crypto === undefined) {
      return Math.floor(1e10 * Math.random());
    }

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const randomArray = new Uint8Array(length);

    crypto.getRandomValues(randomArray);

    return randomArray.reduce((memo, num) => {
      memo += chars[num % chars.length];
      return memo;
    }, "");
  }

  const send = (eventType) => {
    const params = new URLSearchParams({
      pid: propertyId,
      h: location.hostname,
      qs: locationQueryString(),
      n: getRandom()
    });

    if (eventType)
      params.append("ev", eventType);

    if (document.referrer)
      params.append("r", document.referrer);

    const img = new Image();
    const cleanup = () => { img.parentNode.removeChild(img) };

    img.setAttribute("aria-hidden", "true");
    img.style.position = "absolute";
    img.src = `${server}?${params}`;

    img.addEventListener("load", cleanup);
    img.addEventListener("error", cleanup);

    document.body.appendChild(img);

    // TODO: can we use sendBeacon reliably with dealing with CORS?
    // if (navigator.sendBeacon) w{
    //   navigator.sendBeacon(`${server}/v1/beacons`);
    // } else {
    //   // fallback to load an <img> element?
    // }
  }

  return {
    setup(script) {
      if (!script) return;

      propertyId = script.dataset.propertyId;
      server = script.dataset.server;
      configured = propertyId && server;

      if (!propertyId)
        console.debug("MiniBeacon: No data-property-id on <script> tag");
      if (!server)
        console.debug("MiniBeacon: No data-property-id on <script> tag");
    },

    emitPageView: () => {
      if (!configured) return;

      send("view");
    }
  };
}());

MiniBeacon.setup(document.currentScript);
MiniBeacon.emitPageView();
