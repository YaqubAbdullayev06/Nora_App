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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "1270f81b-c665-4ae2-9b22-efe7ba692af8", e._sentryDebugIdIdentifier = "sentry-dbid-1270f81b-c665-4ae2-9b22-efe7ba692af8");
    })();
  } catch (e) {
  }
}
;
import { c8 as useParams, c7 as useNavigate, cp as useSync, ce as useSDK, cb as usePrompt, bY as useDialog, c2 as useLanguage, aE as createMemo, av as createComponent, L as List, b8 as insert, c as Dialog, aX as extractPromptFromParts, am as base64Encode, bJ as showToast, bO as template } from "./main--CpqrD_-.js";
var _tmpl$ = /* @__PURE__ */ template(`<div class="w-full flex items-center gap-2"><span class="truncate flex-1 min-w-0 text-left font-normal"></span><span class="text-text-weak shrink-0 font-normal">`);
function formatTime(date) {
  return date.toLocaleTimeString(void 0, {
    timeStyle: "short"
  });
}
const DialogFork = () => {
  const params = useParams();
  const navigate = useNavigate();
  const sync = useSync();
  const sdk = useSDK();
  const prompt = usePrompt();
  const dialog = useDialog();
  const language = useLanguage();
  const messages = createMemo(() => {
    const sessionID = params.id;
    if (!sessionID) return [];
    const msgs = sync().data.message[sessionID] ?? [];
    const result = [];
    for (const message of msgs) {
      if (message.role !== "user") continue;
      const parts = sync().data.part[message.id] ?? [];
      const textPart = parts.find((x) => x.type === "text" && !x.synthetic && !x.ignored);
      if (!textPart) continue;
      result.push({
        id: message.id,
        text: textPart.text.replace(/\n/g, " ").slice(0, 200),
        time: formatTime(new Date(message.time.created))
      });
    }
    return result.reverse();
  });
  const handleSelect = (item) => {
    if (!item) return;
    const sessionID = params.id;
    if (!sessionID) return;
    const parts = sync().data.part[item.id] ?? [];
    const restored = extractPromptFromParts(parts, {
      directory: sdk().directory,
      attachmentName: language.t("common.attachment")
    });
    const dir = base64Encode(sdk().directory);
    sdk().api.session.fork({
      sessionID,
      messageID: item.id
    }).then((forked) => {
      dialog.close();
      prompt.set(restored, void 0, {
        dir,
        id: forked.id
      });
      navigate(`/${dir}/session/${forked.id}`);
    }).catch((err) => {
      const message = err instanceof Error ? err.message : String(err);
      showToast({
        title: language.t("common.requestFailed"),
        description: message
      });
    });
  };
  return createComponent(Dialog, {
    get title() {
      return language.t("command.session.fork");
    },
    get children() {
      return createComponent(List, {
        "class": "flex-1 px-3 min-h-0 [&_[data-slot=list-scroll]]:flex-1 [&_[data-slot=list-scroll]]:min-h-0",
        get search() {
          return {
            placeholder: language.t("common.search.placeholder"),
            autofocus: true
          };
        },
        get emptyMessage() {
          return language.t("dialog.fork.empty");
        },
        key: (x) => x.id,
        items: messages,
        filterKeys: ["text"],
        onSelect: handleSelect,
        children: (item) => (() => {
          var _el$ = _tmpl$(), _el$2 = _el$.firstChild, _el$3 = _el$2.nextSibling;
          insert(_el$2, () => item.text);
          insert(_el$3, () => item.time);
          return _el$;
        })()
      });
    }
  });
};
export {
  DialogFork
};
//# sourceMappingURL=dialog-fork-B8bRZ7uF.js.map
