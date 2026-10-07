const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./main--CpqrD_-.js","./main-C-FJvlHS.css"])))=>i.map(i=>d[i]);
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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "7ba3e65a-26bc-469f-8865-174999827432", e._sentryDebugIdIdentifier = "sentry-dbid-7ba3e65a-26bc-469f-8865-174999827432");
    })();
  } catch (e) {
  }
}
;
import { ca as usePlatform, c2 as useLanguage, aE as createMemo, bJ as showToast, b8 as insert, bO as template, av as createComponent, bU as useCommand, cn as useSettings, aN as createStore, D as DEFAULT_PALETTE_KEYBIND, bn as onCleanup, a3 as Show, aJ as createRenderEffect, aq as classList, bc as memo, p as For, bI as setAttribute, B as Button, I as Icon, ab as TextField, v as IconButton, a_ as fuzzysort, bp as parseKeybind, bo as onMount, bb as makeEventListener, aY as formatKeybind, a as ButtonV2, ac as TextInputV2, w as IconButtonV2, ba as lazy, ag as __vitePreload, aT as delegateEvents } from "./main--CpqrD_-.js";
import { S as SettingsListV2 } from "./list-cap7HycK.js";
function updaterAction(state) {
  if (!state) return { label: "settings.updates.action.checkNow" };
  switch (state.status) {
    case "checking":
      return { label: "settings.updates.action.checking" };
    case "downloading":
      return { label: "settings.updates.action.downloading" };
    case "ready":
      return { label: "toast.update.action.installRestart", run: "install" };
    case "installing":
      return { label: "settings.updates.action.installing" };
    case "disabled":
      return { label: "settings.updates.action.checkNow" };
    default:
      return { label: "settings.updates.action.checkNow", run: "check" };
  }
}
function useUpdaterAction() {
  const platform = usePlatform();
  const language = useLanguage();
  const action = createMemo(() => updaterAction(platform.updater?.state()));
  return {
    action,
    async run() {
      const run = action().run;
      if (run === "install") return platform.updater?.install();
      if (run !== "check") return;
      const state = await platform.updater?.check();
      if (state?.status === "up-to-date") {
        showToast({
          variant: "success",
          icon: "circle-check",
          title: language.t("settings.updates.toast.latest.title"),
          description: language.t("settings.updates.toast.latest.description", { version: platform.version ?? "" })
        });
      }
      if (state?.status === "error") {
        showToast({ title: language.t("common.requestFailed"), description: state.message });
      }
    }
  };
}
var _tmpl$$1 = /* @__PURE__ */ template(`<div class="bg-surface-base px-4 rounded-lg">`);
const SettingsList = (props) => {
  return (() => {
    var _el$ = _tmpl$$1();
    insert(_el$, () => props.children);
    return _el$;
  })();
};
var _tmpl$ = /* @__PURE__ */ template(`<div class="settings-v2-tab-header settings-v2-tab-header--stacked"><div class=settings-v2-tab-header-row><h2 class=settings-v2-tab-title></h2></div><div class=settings-v2-tab-search>`), _tmpl$2 = /* @__PURE__ */ template(`<div class=settings-v2-shortcuts-status><span></span><span class=settings-v2-shortcuts-status-filter>&quot;<!>&quot;`), _tmpl$3 = /* @__PURE__ */ template(`<div class=settings-v2-tab-body><div class="settings-v2-shortcuts flex flex-col gap-8">`), _tmpl$4 = /* @__PURE__ */ template(`<div class=settings-v2-section><h3 class=settings-v2-section-title>`), _tmpl$5 = /* @__PURE__ */ template(`<div class="flex items-center justify-between gap-4 py-3 border-b border-border-weak-base last:border-none"><span></span><button type=button class=settings-v2-keybind-button>`), _tmpl$6 = /* @__PURE__ */ template(`<span>&quot;<!>&quot;`), _tmpl$7 = /* @__PURE__ */ template(`<div><span>`), _tmpl$8 = /* @__PURE__ */ template(`<div>`), _tmpl$9 = /* @__PURE__ */ template(`<div><h3>`), _tmpl$0 = /* @__PURE__ */ template(`<div class="flex items-center justify-between gap-4 py-3 border-b border-border-weak-base last:border-none"><span></span><button type=button>`), _tmpl$1 = /* @__PURE__ */ template(`<div class="flex flex-col h-full overflow-y-auto no-scrollbar px-4 pb-10 sm:px-10 sm:pb-10"><div class="sticky top-0 z-10 bg-[linear-gradient(to_bottom,var(--surface-stronger-non-alpha)_calc(100%_-_24px),transparent)]"><div class="flex flex-col gap-4 pt-6 pb-6 max-w-[720px]"><div class="flex items-center justify-between gap-4"><h2 class="text-16-medium text-text-strong"></h2></div><div class="flex items-center gap-2 px-3 h-9 rounded-lg bg-surface-base">`);
const IconV2 = lazy(() => __vitePreload(() => import("./main--CpqrD_-.js").then((n) => n.b6), true ? __vite__mapDeps([0,1]) : void 0, import.meta.url).then((module) => ({
  default: module.Icon
})));
const IS_MAC = typeof navigator === "object" && /(Mac|iPod|iPhone|iPad)/.test(navigator.platform);
const PALETTE_ID = "command.palette";
const GROUPS = ["General", "Session", "Navigation", "Model and agent", "Terminal", "Prompt"];
const groupKey = {
  General: "settings.shortcuts.group.general",
  Session: "settings.shortcuts.group.session",
  Navigation: "settings.shortcuts.group.navigation",
  "Model and agent": "settings.shortcuts.group.modelAndAgent",
  Terminal: "settings.shortcuts.group.terminal",
  Prompt: "settings.shortcuts.group.prompt"
};
function groupFor(id) {
  if (id === PALETTE_ID) return "General";
  if (id.startsWith("terminal.")) return "Terminal";
  if (id.startsWith("model.") || id.startsWith("agent.") || id.startsWith("mcp.")) return "Model and agent";
  if (id.startsWith("file.") || id.startsWith("fileTree.")) return "Navigation";
  if (id.startsWith("prompt.")) return "Prompt";
  if (id.startsWith("session.") || id.startsWith("message.") || id.startsWith("permissions.") || id.startsWith("steps.") || id.startsWith("review.")) return "Session";
  return "General";
}
function isModifier(key) {
  return key === "Shift" || key === "Control" || key === "Alt" || key === "Meta";
}
function normalizeKey(key) {
  if (key === ",") return "comma";
  if (key === "+") return "plus";
  if (key === " ") return "space";
  return key.toLowerCase();
}
function recordKeybind(event) {
  if (isModifier(event.key)) return;
  const parts = [];
  const mod = IS_MAC ? event.metaKey : event.ctrlKey;
  if (mod) parts.push("mod");
  if (IS_MAC && event.ctrlKey) parts.push("ctrl");
  if (!IS_MAC && event.metaKey) parts.push("meta");
  if (event.altKey) parts.push("alt");
  if (event.shiftKey) parts.push("shift");
  const key = normalizeKey(event.key);
  if (!key) return;
  parts.push(key);
  return parts.join("+");
}
function signatures(config) {
  if (!config) return [];
  const sigs = [];
  for (const kb of parseKeybind(config)) {
    const parts = [];
    if (kb.ctrl) parts.push("ctrl");
    if (kb.alt) parts.push("alt");
    if (kb.shift) parts.push("shift");
    if (kb.meta) parts.push("meta");
    if (kb.key) parts.push(kb.key);
    if (parts.length === 0) continue;
    sigs.push(parts.join("+"));
  }
  return sigs;
}
function keybinds(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value;
}
function listFor(command, map, palette) {
  const out = /* @__PURE__ */ new Map();
  out.set(PALETTE_ID, {
    title: palette,
    group: "General"
  });
  for (const opt of command.catalog) {
    if (opt.id.startsWith("suggested.")) continue;
    if (opt.hidden) continue;
    out.set(opt.id, {
      title: opt.title,
      group: groupFor(opt.id)
    });
  }
  for (const opt of command.options) {
    if (opt.id.startsWith("suggested.")) continue;
    if (opt.hidden) continue;
    out.set(opt.id, {
      title: opt.title,
      group: groupFor(opt.id)
    });
  }
  for (const [id, value] of Object.entries(map)) {
    if (typeof value !== "string") continue;
    if (out.has(id)) continue;
    out.set(id, {
      title: id,
      group: groupFor(id)
    });
  }
  return out;
}
function groupedFor(list) {
  const out = /* @__PURE__ */ new Map();
  for (const group of GROUPS) out.set(group, []);
  for (const [id, item] of list) {
    const ids = out.get(item.group);
    if (!ids) continue;
    ids.push(id);
  }
  for (const group of GROUPS) {
    const ids = out.get(group);
    if (!ids) continue;
    ids.sort((a, b) => (list.get(a)?.title ?? "").localeCompare(list.get(b)?.title ?? ""));
  }
  return out;
}
function filteredFor(query, list, grouped, keybind) {
  const value = query.toLowerCase().trim();
  if (!value) return grouped;
  const out = /* @__PURE__ */ new Map();
  for (const group of GROUPS) out.set(group, []);
  const items = Array.from(list.entries()).map(([id, meta]) => ({
    id,
    title: meta.title,
    group: meta.group,
    keybind: keybind(id)
  }));
  const results = fuzzysort.go(value, items, {
    keys: ["title", "keybind"],
    threshold: -1e4
  });
  for (const result of results) {
    const ids = out.get(result.obj.group);
    if (!ids) continue;
    ids.push(result.obj.id);
  }
  return out;
}
function useKeyCapture(input) {
  onMount(() => {
    const handle = (event) => {
      const id = input.active();
      if (!id) return;
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      if (event.key === "Escape") {
        input.stop();
        return;
      }
      const clear = (event.key === "Backspace" || event.key === "Delete") && !event.ctrlKey && !event.metaKey && !event.altKey && !event.shiftKey;
      if (clear) {
        input.set(id, "none");
        input.stop();
        return;
      }
      const next = recordKeybind(event);
      if (!next) return;
      const conflicts = /* @__PURE__ */ new Map();
      for (const sig of signatures(next)) {
        for (const item of input.used().get(sig) ?? []) {
          if (item.id === id) continue;
          conflicts.set(item.id, item.title);
        }
      }
      if (conflicts.size > 0) {
        showToast({
          title: input.language.t("settings.shortcuts.conflict.title"),
          description: input.language.t("settings.shortcuts.conflict.description", {
            keybind: formatKeybind(next, input.language.t),
            titles: [...conflicts.values()].join(", ")
          })
        });
        return;
      }
      input.set(id, next);
      input.stop();
    };
    makeEventListener(document, "keydown", handle, {
      capture: true
    });
  });
}
function createKeybindSettingsController(input, language = useLanguage()) {
  const [store, setStore] = createStore({
    active: null
  });
  const overrides = createMemo(() => keybinds(input.settings.current.keybinds));
  const list = createMemo(() => {
    language.locale();
    return listFor(input.command, overrides(), language.t("command.palette"));
  });
  const grouped = createMemo(() => groupedFor(list()));
  const title = (id) => list().get(id)?.title ?? "";
  const effective = (id) => {
    if (id === PALETTE_ID) return input.settings.keybinds.get(id) ?? DEFAULT_PALETTE_KEYBIND;
    const custom = input.settings.keybinds.get(id);
    if (typeof custom === "string") return custom;
    const live = input.command.options.find((item) => item.id === id);
    if (live?.keybind) return live.keybind;
    return input.command.catalog.find((item) => item.id === id)?.keybind;
  };
  const used = createMemo(() => {
    const value = /* @__PURE__ */ new Map();
    for (const id of list().keys()) {
      for (const signature of signatures(effective(id))) {
        const items = value.get(signature);
        if (items) {
          items.push({
            id,
            title: title(id)
          });
          continue;
        }
        value.set(signature, [{
          id,
          title: title(id)
        }]);
      }
    }
    return value;
  });
  const stop = () => {
    if (!store.active) return;
    setStore("active", null);
    input.command.keybinds(true);
  };
  const toggle = (id) => {
    if (store.active === id) {
      stop();
      return;
    }
    if (store.active) stop();
    setStore("active", id);
    input.command.keybinds(false);
  };
  const notify = input.notify ?? ((toast) => showToast(toast));
  const handle = (event) => {
    const id = store.active;
    if (!id) return;
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    if (event.key === "Escape") {
      stop();
      return;
    }
    const clear = (event.key === "Backspace" || event.key === "Delete") && !event.ctrlKey && !event.metaKey && !event.altKey && !event.shiftKey;
    if (clear) {
      input.settings.keybinds.set(id, "none");
      stop();
      return;
    }
    const next = recordKeybind(event);
    if (!next) return;
    const conflicts = /* @__PURE__ */ new Map();
    for (const signature of signatures(next)) {
      for (const item of used().get(signature) ?? []) {
        if (item.id === id) continue;
        conflicts.set(item.id, item.title);
      }
    }
    if (conflicts.size > 0) {
      notify({
        title: language.t("settings.shortcuts.conflict.title"),
        description: language.t("settings.shortcuts.conflict.description", {
          keybind: formatKeybind(next, language.t),
          titles: [...conflicts.values()].join(", ")
        })
      });
      return;
    }
    input.settings.keybinds.set(id, next);
    stop();
  };
  const target = input.target ?? (typeof document === "object" ? document : void 0);
  if (target) makeEventListener(target, "keydown", handle, {
    capture: true
  });
  onCleanup(() => {
    if (store.active) input.command.keybinds(true);
  });
  return {
    catalog: {
      groups: GROUPS,
      filtered: (query) => filteredFor(query, list(), grouped(), (id) => formatKeybind(effective(id) ?? "", language.t)),
      title,
      keybind: (id) => formatKeybind(effective(id) ?? "", language.t)
    },
    capture: {
      active: () => store.active,
      toggle
    },
    settings: {
      hasOverrides: () => Object.values(overrides()).some((value) => typeof value === "string"),
      reset: () => {
        stop();
        input.settings.keybinds.resetAll();
        notify({
          title: language.t("settings.shortcuts.reset.toast.title"),
          description: language.t("settings.shortcuts.reset.toast.description")
        });
      }
    }
  };
}
function SettingsKeybindsV2() {
  const command = useCommand();
  const settings = useSettings();
  const controller = createKeybindSettingsController({
    command,
    settings
  });
  return createComponent(SettingsKeybindsV2View, {
    get groups() {
      return controller.catalog.groups;
    },
    get filtered() {
      return controller.catalog.filtered;
    },
    get title() {
      return controller.catalog.title;
    },
    get keybind() {
      return controller.catalog.keybind;
    },
    get active() {
      return controller.capture.active;
    },
    get onCapture() {
      return controller.capture.toggle;
    },
    get hasOverrides() {
      return controller.settings.hasOverrides;
    },
    get onReset() {
      return controller.settings.reset;
    }
  });
}
function SettingsKeybindsV2View(props) {
  const language = useLanguage();
  const [store, setStore] = createStore({
    filter: ""
  });
  const filtered = createMemo(() => props.filtered(store.filter));
  const hasResults = createMemo(() => props.groups.some((group) => (filtered().get(group)?.length ?? 0) > 0));
  return [(() => {
    var _el$ = _tmpl$(), _el$2 = _el$.firstChild, _el$3 = _el$2.firstChild, _el$4 = _el$2.nextSibling;
    insert(_el$3, () => language.t("settings.shortcuts.title"));
    insert(_el$2, createComponent(ButtonV2, {
      variant: "ghost",
      get onClick() {
        return props.onReset;
      },
      get disabled() {
        return !props.hasOverrides();
      },
      get children() {
        return language.t("settings.shortcuts.reset.button");
      }
    }), null);
    insert(_el$4, createComponent(TextInputV2, {
      type: "search",
      appearance: "base",
      get value() {
        return store.filter;
      },
      onInput: (event) => setStore("filter", event.currentTarget.value),
      get placeholder() {
        return language.t("settings.shortcuts.search.placeholder");
      },
      spellcheck: false,
      autocorrect: "off",
      autocomplete: "off",
      autocapitalize: "off",
      get ["aria-label"]() {
        return language.t("settings.shortcuts.search.placeholder");
      }
    }), null);
    insert(_el$4, createComponent(Show, {
      get when() {
        return store.filter;
      },
      get children() {
        return createComponent(IconButtonV2, {
          type: "button",
          variant: "ghost-muted",
          size: "small",
          "class": "settings-v2-tab-search-clear",
          get icon() {
            return createComponent(IconV2, {
              name: "close",
              size: "large",
              "class": "text-v2-icon-icon-muted"
            });
          },
          onClick: () => setStore("filter", "")
        });
      }
    }), null);
    return _el$;
  })(), (() => {
    var _el$5 = _tmpl$3(), _el$6 = _el$5.firstChild;
    insert(_el$6, createComponent(For, {
      get each() {
        return props.groups;
      },
      children: (group) => createComponent(Show, {
        get when() {
          return (filtered().get(group) ?? []).length > 0;
        },
        get children() {
          var _el$11 = _tmpl$4(), _el$12 = _el$11.firstChild;
          insert(_el$12, () => language.t(groupKey[group]));
          insert(_el$11, createComponent(SettingsListV2, {
            get children() {
              return createComponent(For, {
                get each() {
                  return filtered().get(group) ?? [];
                },
                children: (id) => (() => {
                  var _el$13 = _tmpl$5(), _el$14 = _el$13.firstChild, _el$15 = _el$14.nextSibling;
                  insert(_el$14, () => props.title(id));
                  _el$15.$$click = () => props.onCapture(id);
                  setAttribute(_el$15, "data-keybind-id", id);
                  insert(_el$15, createComponent(Show, {
                    get when() {
                      return props.active() === id;
                    },
                    get fallback() {
                      return props.keybind(id) || language.t("settings.shortcuts.unassigned");
                    },
                    get children() {
                      return language.t("settings.shortcuts.pressKeys");
                    }
                  }));
                  createRenderEffect(() => _el$15.classList.toggle("settings-v2-keybind-button--active", !!(props.active() === id)));
                  return _el$13;
                })()
              });
            }
          }), null);
          return _el$11;
        }
      })
    }), null);
    insert(_el$6, createComponent(Show, {
      get when() {
        return memo(() => !!store.filter)() && !hasResults();
      },
      get children() {
        var _el$7 = _tmpl$2(), _el$8 = _el$7.firstChild, _el$9 = _el$8.nextSibling, _el$0 = _el$9.firstChild, _el$10 = _el$0.nextSibling;
        _el$10.nextSibling;
        insert(_el$8, () => language.t("settings.shortcuts.search.empty"));
        insert(_el$9, () => store.filter, _el$10);
        return _el$7;
      }
    }), null);
    return _el$5;
  })()];
}
const SettingsKeybinds = (props) => {
  if (props.v2) return createComponent(SettingsKeybindsV2, {});
  const command = useCommand();
  const language = useLanguage();
  const settings = useSettings();
  const [store, setStore] = createStore({
    active: null,
    filter: ""
  });
  const stop = () => {
    if (!store.active) return;
    setStore("active", null);
    command.keybinds(true);
  };
  const start = (id) => {
    if (store.active === id) {
      stop();
      return;
    }
    if (store.active) stop();
    setStore("active", id);
    command.keybinds(false);
  };
  const map = createMemo(() => keybinds(settings.current.keybinds));
  const hasOverrides = createMemo(() => Object.values(map()).some((x) => typeof x === "string"));
  const resetAll = () => {
    stop();
    settings.keybinds.resetAll();
    showToast({
      title: language.t("settings.shortcuts.reset.toast.title"),
      description: language.t("settings.shortcuts.reset.toast.description")
    });
  };
  const list = createMemo(() => {
    language.locale();
    return listFor(command, map(), language.t("command.palette"));
  });
  const title = (id) => list().get(id)?.title ?? "";
  const grouped = createMemo(() => groupedFor(list()));
  const filtered = createMemo(() => {
    return filteredFor(store.filter, list(), grouped(), (id) => command.keybind(id) || "");
  });
  const hasResults = createMemo(() => {
    for (const group of GROUPS) {
      const ids = filtered().get(group) ?? [];
      if (ids.length > 0) return true;
    }
    return false;
  });
  const used = createMemo(() => {
    const map2 = /* @__PURE__ */ new Map();
    const add = (key, value) => {
      const list2 = map2.get(key);
      if (!list2) {
        map2.set(key, [value]);
        return;
      }
      list2.push(value);
    };
    const palette = settings.keybinds.get(PALETTE_ID) ?? DEFAULT_PALETTE_KEYBIND;
    for (const sig of signatures(palette)) {
      add(sig, {
        id: PALETTE_ID,
        title: title(PALETTE_ID)
      });
    }
    const valueFor = (id) => {
      const custom = settings.keybinds.get(id);
      if (typeof custom === "string") return custom;
      const live = command.options.find((x) => x.id === id);
      if (live?.keybind) return live.keybind;
      const meta = command.catalog.find((x) => x.id === id);
      return meta?.keybind;
    };
    for (const id of list().keys()) {
      if (id === PALETTE_ID) continue;
      for (const sig of signatures(valueFor(id))) {
        add(sig, {
          id,
          title: title(id)
        });
      }
    }
    return map2;
  });
  const setKeybind = (id, keybind) => settings.keybinds.set(id, keybind);
  useKeyCapture({
    active: () => store.active,
    stop,
    set: setKeybind,
    used,
    language
  });
  onCleanup(() => {
    if (store.active) command.keybinds(true);
  });
  const emptyResults = createComponent(Show, {
    get when() {
      return memo(() => !!store.filter)() && !hasResults();
    },
    get children() {
      var _el$16 = _tmpl$7(), _el$17 = _el$16.firstChild;
      insert(_el$17, () => language.t("settings.shortcuts.search.empty"));
      insert(_el$16, createComponent(Show, {
        get when() {
          return store.filter;
        },
        get children() {
          var _el$18 = _tmpl$6(), _el$19 = _el$18.firstChild, _el$21 = _el$19.nextSibling;
          _el$21.nextSibling;
          insert(_el$18, () => store.filter, _el$21);
          createRenderEffect((_$p) => classList(_el$18, {
            "text-14-regular text-text-strong mt-1": !props.v2,
            "settings-v2-shortcuts-status-filter": props.v2
          }, _$p));
          return _el$18;
        }
      }), null);
      createRenderEffect((_p$) => {
        var _v$ = {
          "flex flex-col items-center justify-center py-12 text-center": !props.v2,
          "settings-v2-shortcuts-status": props.v2
        }, _v$2 = {
          "text-14-regular text-text-weak": !props.v2
        };
        _p$.e = classList(_el$16, _v$, _p$.e);
        _p$.t = classList(_el$17, _v$2, _p$.t);
        return _p$;
      }, {
        e: void 0,
        t: void 0
      });
      return _el$16;
    }
  });
  const List = props.v2 ? SettingsListV2 : SettingsList;
  const groups = (() => {
    var _el$22 = _tmpl$8();
    insert(_el$22, createComponent(For, {
      each: GROUPS,
      children: (group) => createComponent(Show, {
        get when() {
          return (filtered().get(group) ?? []).length > 0;
        },
        get children() {
          var _el$23 = _tmpl$9(), _el$24 = _el$23.firstChild;
          insert(_el$24, () => language.t(groupKey[group]));
          insert(_el$23, createComponent(List, {
            get children() {
              return createComponent(For, {
                get each() {
                  return filtered().get(group) ?? [];
                },
                children: (id) => (() => {
                  var _el$25 = _tmpl$0(), _el$26 = _el$25.firstChild, _el$27 = _el$26.nextSibling;
                  insert(_el$26, () => title(id));
                  _el$27.$$click = () => start(id);
                  setAttribute(_el$27, "data-keybind-id", id);
                  insert(_el$27, createComponent(Show, {
                    get when() {
                      return store.active === id;
                    },
                    get fallback() {
                      return command.keybind(id) || language.t("settings.shortcuts.unassigned");
                    },
                    get children() {
                      return language.t("settings.shortcuts.pressKeys");
                    }
                  }));
                  createRenderEffect((_p$) => {
                    var _v$5 = {
                      "text-14-regular text-text-strong": !props.v2
                    }, _v$6 = {
                      "settings-v2-keybind-button": props.v2,
                      "settings-v2-keybind-button--active": props.v2 && store.active === id,
                      "h-8 px-3 rounded-md text-12-regular": !props.v2,
                      "bg-surface-base text-text-subtle hover:bg-surface-raised-base-hover active:bg-surface-raised-base-active": !props.v2 && store.active !== id,
                      "border border-border-weak-base bg-surface-inset-base text-text-weak": !props.v2 && store.active === id
                    };
                    _p$.e = classList(_el$26, _v$5, _p$.e);
                    _p$.t = classList(_el$27, _v$6, _p$.t);
                    return _p$;
                  }, {
                    e: void 0,
                    t: void 0
                  });
                  return _el$25;
                })()
              });
            }
          }), null);
          createRenderEffect((_p$) => {
            var _v$3 = {
              "settings-v2-section": props.v2,
              "flex flex-col gap-1": !props.v2
            }, _v$4 = {
              "settings-v2-section-title": props.v2,
              "text-14-medium text-text-strong pb-2": !props.v2
            };
            _p$.e = classList(_el$23, _v$3, _p$.e);
            _p$.t = classList(_el$24, _v$4, _p$.t);
            return _p$;
          }, {
            e: void 0,
            t: void 0
          });
          return _el$23;
        }
      })
    }), null);
    insert(_el$22, emptyResults, null);
    createRenderEffect((_$p) => classList(_el$22, {
      "settings-v2-shortcuts flex flex-col gap-8": props.v2,
      "flex flex-col gap-8 max-w-[720px]": !props.v2
    }, _$p));
    return _el$22;
  })();
  return (() => {
    var _el$28 = _tmpl$1(), _el$29 = _el$28.firstChild, _el$30 = _el$29.firstChild, _el$31 = _el$30.firstChild, _el$32 = _el$31.firstChild, _el$33 = _el$31.nextSibling;
    insert(_el$32, () => language.t("settings.shortcuts.title"));
    insert(_el$31, createComponent(Button, {
      size: "small",
      variant: "secondary",
      onClick: resetAll,
      get disabled() {
        return !hasOverrides();
      },
      get children() {
        return language.t("settings.shortcuts.reset.button");
      }
    }), null);
    insert(_el$33, createComponent(Icon, {
      name: "magnifying-glass",
      "class": "text-icon-weak-base flex-shrink-0"
    }), null);
    insert(_el$33, createComponent(TextField, {
      variant: "ghost",
      type: "text",
      get value() {
        return store.filter;
      },
      onChange: (v) => setStore("filter", v),
      get placeholder() {
        return language.t("settings.shortcuts.search.placeholder");
      },
      spellcheck: false,
      autocorrect: "off",
      autocomplete: "off",
      autocapitalize: "off",
      "class": "flex-1"
    }), null);
    insert(_el$33, createComponent(Show, {
      get when() {
        return store.filter;
      },
      get children() {
        return createComponent(IconButton, {
          icon: "circle-x",
          variant: "ghost",
          onClick: () => setStore("filter", "")
        });
      }
    }), null);
    insert(_el$28, groups, null);
    return _el$28;
  })();
};
delegateEvents(["click"]);
export {
  SettingsKeybinds as S,
  SettingsList as a,
  useUpdaterAction as u
};
//# sourceMappingURL=settings-keybinds-1JWVAFPD.js.map
