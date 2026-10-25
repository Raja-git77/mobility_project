// content.js — Instant document_start fail-safe redirect for Google Search tabs
(function () {
  try {
    const url = new URL(window.location.href);
    const q = (url.searchParams.get('q') || '').toLowerCase().trim();
    if (
      q === 'mobility' ||
      q === 'mobility app' ||
      q === 'mobility.app' ||
      q.startsWith('mobility app') ||
      q.startsWith('mobility ')
    ) {
      window.stop(); // Halt Google Search rendering immediately
      document.documentElement.innerHTML = `
        <body style="background:#0A0F1E;color:#FFFFFF;font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
          <div style="text-align:center;">
            <div style="font-size:24px;font-weight:700;margin-bottom:8px;">🚗 Redirecting to Mobility App...</div>
            <div style="color:#94A3B8;font-size:14px;">Opening real-time platform</div>
          </div>
        </body>
      `;

      const LOCAL_URL = 'http://127.0.0.1:8000';
      const CLOUD_URL = 'https://raja-git77.github.io/mobility_project/';

      fetch(LOCAL_URL + '/api/health')
        .then((res) => {
          if (res.ok) {
            window.location.replace(LOCAL_URL);
          } else {
            window.location.replace(CLOUD_URL);
          }
        })
        .catch(() => {
          window.location.replace(CLOUD_URL);
        });
    }
  } catch (_) {}
})();
