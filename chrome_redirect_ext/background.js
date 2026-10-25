// background.js — Intercepts Omnibox Google searches for "mobility" or "mobility app"
const LOCAL_URL = 'http://127.0.0.1:8000';
const CLOUD_URL = 'https://raja-git77.github.io/mobility_project/';

async function determineTargetUrl() {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 800);
    const resp = await fetch(LOCAL_URL + '/api/health', { method: 'GET', signal: controller.signal });
    clearTimeout(timeoutId);
    if (resp.ok) {
      return LOCAL_URL;
    }
  } catch (_) {}
  return CLOUD_URL;
}

chrome.webNavigation.onBeforeNavigate.addListener(async (details) => {
  if (details.frameId !== 0) return; // Main frame only
  try {
    const url = new URL(details.url);
    if (url.hostname.includes('google.') && url.pathname.includes('/search')) {
      const q = (url.searchParams.get('q') || '').toLowerCase().trim();
      if (
        q === 'mobility' ||
        q === 'mobility app' ||
        q === 'mobility.app' ||
        q.startsWith('mobility app') ||
        q.startsWith('mobility ')
      ) {
        console.log('[MobilityExt] Intercepting Google Search for query:', q);
        const target = await determineTargetUrl();
        chrome.tabs.update(details.tabId, { url: target });
      }
    }
  } catch (err) {
    console.error('[MobilityExt] Error during navigation interception:', err);
  }
}, {
  url: [
    { hostContains: 'google.', pathContains: '/search' }
  ]
});
