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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "1b8be483-e526-4f10-afbd-5a622203d9fc", e._sentryDebugIdIdentifier = "sentry-dbid-1b8be483-e526-4f10-afbd-5a622203d9fc");
    })();
  } catch (e) {
  }
}
;
import { b8 as insert, bO as template } from "./main--CpqrD_-.js";
var _tmpl$ = /* @__PURE__ */ template(`<div data-component=settings-v2-list>`);
const SettingsListV2 = (props) => {
  return (() => {
    var _el$ = _tmpl$();
    insert(_el$, () => props.children);
    return _el$;
  })();
};
export {
  SettingsListV2 as S
};
//# sourceMappingURL=list-cap7HycK.js.map
