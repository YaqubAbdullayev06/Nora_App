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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "5b41d0a5-b833-4b72-857d-b05d082f6100", e._sentryDebugIdIdentifier = "sentry-dbid-5b41d0a5-b833-4b72-857d-b05d082f6100");
    })();
  } catch (e) {
  }
}
;
import { S as Switch$1 } from "./LROKH5N7-DNLoZdIV.js";
import { bL as splitProps, av as createComponent, be as mergeProps, a3 as Show } from "./main--CpqrD_-.js";
function Switch(props) {
  const [local, others] = splitProps(props, ["children", "class", "hideLabel", "description"]);
  return createComponent(Switch$1, mergeProps(others, {
    get ["class"]() {
      return local.class;
    },
    "data-component": "switch",
    get children() {
      return [createComponent(Switch$1.Input, {
        "data-slot": "switch-input"
      }), createComponent(Show, {
        get when() {
          return local.children;
        },
        get children() {
          return createComponent(Switch$1.Label, {
            "data-slot": "switch-label",
            get classList() {
              return {
                "sr-only": local.hideLabel
              };
            },
            get children() {
              return local.children;
            }
          });
        }
      }), createComponent(Show, {
        get when() {
          return local.description;
        },
        get children() {
          return createComponent(Switch$1.Description, {
            "data-slot": "switch-description",
            get children() {
              return local.description;
            }
          });
        }
      }), createComponent(Switch$1.ErrorMessage, {
        "data-slot": "switch-error"
      }), createComponent(Switch$1.Control, {
        "data-slot": "switch-control",
        get children() {
          return createComponent(Switch$1.Thumb, {
            "data-slot": "switch-thumb"
          });
        }
      })];
    }
  }));
}
export {
  Switch as S
};
//# sourceMappingURL=switch-6so6iqHS.js.map
