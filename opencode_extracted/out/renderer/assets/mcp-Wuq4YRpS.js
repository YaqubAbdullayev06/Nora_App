!(function() {
  try {
    var e = "undefined" != typeof window ? window : "undefined" != typeof global ? global : "undefined" != typeof globalThis ? globalThis : "undefined" != typeof self ? self : {};
    e.SENTRY_RELEASE = { id: "desktop@1.18.33" };
  } catch (e2) {
  }
})();
;
{
  try {
    (function() {
      var e = "undefined" != typeof window ? window : "undefined" != typeof global ? global : "undefined" != typeof globalThis ? globalThis : "undefined" != typeof self ? self : {}, n = new e.Error().stack;
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "eb2b3ad8-bad5-4c79-9067-80adc3a137a2", e._sentryDebugIdIdentifier = "sentry-dbid-eb2b3ad8-bad5-4c79-9067-80adc3a137a2");
    })();
  } catch (e) {
  }
}
;
import { cp as useSync, c2 as useLanguage, c6 as useMutation, bJ as showToast } from "./main--CpqrD_-.js";
function useMcpToggle() {
  const sync = useSync();
  const language = useLanguage();
  return useMutation(() => ({
    mutationFn: sync().mcp.toggle,
    onError: (error) => showToast({
      variant: "error",
      title: language.t("common.requestFailed"),
      description: error instanceof Error ? error.message : String(error)
    })
  }));
}
export {
  useMcpToggle as u
};
//# sourceMappingURL=mcp-Wuq4YRpS.js.map
