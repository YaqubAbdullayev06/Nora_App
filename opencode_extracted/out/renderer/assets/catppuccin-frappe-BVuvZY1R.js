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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "7f9cd31e-0f3a-43b8-9986-799192dc10ca", e._sentryDebugIdIdentifier = "sentry-dbid-7f9cd31e-0f3a-43b8-9986-799192dc10ca");
    })();
  } catch (e) {
  }
}
;
const $schema = "https://opencode.ai/desktop-theme.json";
const name = "Catppuccin Frappe";
const id = "catppuccin-frappe";
const light = { "palette": { "neutral": "#303446", "ink": "#c6d0f5", "primary": "#8da4e2", "accent": "#f4b8e4", "success": "#a6d189", "warning": "#e5c890", "error": "#e78284", "info": "#81c8be" }, "overrides": { "text-weak": "#b5bfe2", "syntax-comment": "#949cb8", "syntax-keyword": "#ca9ee6", "syntax-string": "#a6d189", "syntax-primitive": "#8da4e2", "syntax-variable": "#e78284", "syntax-property": "#99d1db", "syntax-type": "#e5c890", "syntax-constant": "#ef9f76", "syntax-operator": "#99d1db", "syntax-punctuation": "#c6d0f5", "syntax-object": "#e78284", "markdown-heading": "#ca9ee6", "markdown-text": "#c6d0f5", "markdown-link": "#8da4e2", "markdown-link-text": "#99d1db", "markdown-code": "#a6d189", "markdown-block-quote": "#e5c890", "markdown-emph": "#e5c890", "markdown-strong": "#ef9f76", "markdown-horizontal-rule": "#a5adce", "markdown-list-item": "#8da4e2", "markdown-list-enumeration": "#99d1db", "markdown-image": "#8da4e2", "markdown-image-text": "#99d1db", "markdown-code-block": "#c6d0f5" } };
const dark = { "palette": { "neutral": "#303446", "ink": "#c6d0f5", "primary": "#8da4e2", "accent": "#f4b8e4", "success": "#a6d189", "warning": "#e5c890", "error": "#e78284", "info": "#81c8be" }, "overrides": { "text-weak": "#b5bfe2", "syntax-comment": "#949cb8", "syntax-keyword": "#ca9ee6", "syntax-string": "#a6d189", "syntax-primitive": "#8da4e2", "syntax-variable": "#e78284", "syntax-property": "#99d1db", "syntax-type": "#e5c890", "syntax-constant": "#ef9f76", "syntax-operator": "#99d1db", "syntax-punctuation": "#c6d0f5", "syntax-object": "#e78284", "markdown-heading": "#ca9ee6", "markdown-text": "#c6d0f5", "markdown-link": "#8da4e2", "markdown-link-text": "#99d1db", "markdown-code": "#a6d189", "markdown-block-quote": "#e5c890", "markdown-emph": "#e5c890", "markdown-strong": "#ef9f76", "markdown-horizontal-rule": "#a5adce", "markdown-list-item": "#8da4e2", "markdown-list-enumeration": "#99d1db", "markdown-image": "#8da4e2", "markdown-image-text": "#99d1db", "markdown-code-block": "#c6d0f5" } };
const catppuccinFrappeThemeJson = {
  $schema,
  name,
  id,
  light,
  dark
};
export {
  $schema,
  dark,
  catppuccinFrappeThemeJson as default,
  id,
  light,
  name
};
//# sourceMappingURL=catppuccin-frappe-BVuvZY1R.js.map
