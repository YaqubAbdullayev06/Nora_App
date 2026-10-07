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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "0568b1c7-23e2-4624-b390-7c818667725c", e._sentryDebugIdIdentifier = "sentry-dbid-0568b1c7-23e2-4624-b390-7c818667725c");
    })();
  } catch (e) {
  }
}
;
const $schema = "https://opencode.ai/desktop-theme.json";
const name = "Aura";
const id = "aura";
const light = { "palette": { "neutral": "#f5f0ff", "ink": "#2d2640", "primary": "#a277ff", "accent": "#d94f4f", "success": "#40bf7a", "warning": "#d9a24a", "error": "#d94f4f", "info": "#5bb8d9", "diffAdd": "#b3e6cc", "diffDelete": "#f5b3b3" }, "overrides": { "syntax-comment": "#8d88a3", "syntax-keyword": "#7b5ae0", "syntax-string": "#2b8a57", "syntax-primitive": "#2f78b8", "syntax-property": "#a96a22", "syntax-type": "#2b8a57", "syntax-constant": "#d94f4f" } };
const dark = { "palette": { "neutral": "#15141b", "ink": "#edecee", "primary": "#a277ff", "accent": "#ff6767", "success": "#61ffca", "warning": "#ffca85", "error": "#ff6767", "info": "#82e2ff", "diffAdd": "#61ffca", "diffDelete": "#ff6767" }, "overrides": { "syntax-comment": "#6d6a7e", "syntax-keyword": "#a277ff", "syntax-string": "#61ffca", "syntax-primitive": "#82e2ff", "syntax-property": "#ffca85", "syntax-type": "#61ffca", "syntax-constant": "#ff6767" } };
const auraThemeJson = {
  $schema,
  name,
  id,
  light,
  dark
};
export {
  $schema,
  dark,
  auraThemeJson as default,
  id,
  light,
  name
};
//# sourceMappingURL=aura-B69YaCaU.js.map
