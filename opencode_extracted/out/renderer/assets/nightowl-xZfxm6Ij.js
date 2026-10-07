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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "867dc765-6bb1-4a5d-9d98-72716bd71968", e._sentryDebugIdIdentifier = "sentry-dbid-867dc765-6bb1-4a5d-9d98-72716bd71968");
    })();
  } catch (e) {
  }
}
;
const $schema = "https://opencode.ai/desktop-theme.json";
const name = "Night Owl";
const id = "nightowl";
const light = { "palette": { "neutral": "#f0f0f0", "ink": "#403f53", "primary": "#4876d6", "accent": "#aa0982", "success": "#2aa298", "warning": "#c96765", "error": "#de3d3b", "info": "#4876d6", "diffAdd": "#2aa298", "diffDelete": "#de3d3b" }, "overrides": { "syntax-comment": "#7a8181", "syntax-keyword": "#994cc3", "syntax-primitive": "#4876d6", "syntax-constant": "#c96765" } };
const dark = { "palette": { "neutral": "#011627", "ink": "#d6deeb", "primary": "#82aaff", "accent": "#f78c6c", "success": "#c5e478", "warning": "#ecc48d", "error": "#ef5350", "info": "#82aaff", "diffAdd": "#c5e478", "diffDelete": "#ef5350" }, "overrides": { "syntax-comment": "#637777", "syntax-keyword": "#c792ea", "syntax-string": "#ecc48d", "syntax-primitive": "#82aaff", "syntax-constant": "#f78c6c" } };
const nightowlThemeJson = {
  $schema,
  name,
  id,
  light,
  dark
};
export {
  $schema,
  dark,
  nightowlThemeJson as default,
  id,
  light,
  name
};
//# sourceMappingURL=nightowl-xZfxm6Ij.js.map
