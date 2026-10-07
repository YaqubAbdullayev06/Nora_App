const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./dialog-settings-DmYK2SOV.js","./main--CpqrD_-.js","./main-C-FJvlHS.css","./switch-6so6iqHS.js","./LROKH5N7-DNLoZdIV.js","./settings-keybinds-1JWVAFPD.js","./list-cap7HycK.js","./dialog-connect-provider-CSAzTPRb.js"])))=>i.map(i=>d[i]);
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
      n && (e._sentryDebugIds = e._sentryDebugIds || {}, e._sentryDebugIds[n] = "febcd8e3-0a0f-4c67-a5ea-991c9541c022", e._sentryDebugIdIdentifier = "sentry-dbid-febcd8e3-0a0f-4c67-a5ea-991c9541c022");
    })();
  } catch (e) {
  }
}
;
import { bL as splitProps, av as createComponent, be as mergeProps, a7 as Tabs, b8 as insert, c1 as useI18n, bM as spread, a3 as Show, aJ as createRenderEffect, bI as setAttribute, aq as classList, bO as template, aT as delegateEvents, aa as Tag, a as ButtonV2, bn as onCleanup, c9 as usePermission, ck as useServerSync, aE as createMemo, cj as useServerSDK, aK as createResource, cn as useSettings, cr as useTheme, bo as onMount, bP as terminalDefault, bQ as terminalFontFamily, bR as terminalInput, bg as monoDefault, bh as monoFontFamily, bi as monoInput, bE as sansDefault, bF as sansFontFamily, bG as sansInput, S as SOUND_OPTIONS, bx as playSoundById, c2 as useLanguage, ca as usePlatform, bY as useDialog, aD as createMediaQuery, ag as __vitePreload, bc as memo, V as SelectV2, ac as TextInputV2, ci as useServerProtocol, cd as useProviders, by as popularProviders, p as For, O as ProviderIcon, bJ as showToast, c5 as useModels, br as persisted, aN as createStore, C as Persist, b_ as useFilteredList, w as IconButtonV2, u as Icon, R as RadioGroup, a_ as fuzzysort, c6 as useMutation, ay as createEffect, d as Dialog, g as DialogHeader, i as DialogTitle, l as DividerV2, e as DialogBody, ak as addEventListener, f as DialogFooter, ct as useWslServers, bK as showToast$1, y as MenuV2, W as ServerConnection, Z as ServerHealthIndicator, ch as useServerManagementController, bH as serverName, $ as ServerRowMenu, h as DialogServerV2, c3 as useLayout, cq as useTabs, aM as createSignal, I as Icon$1, bN as startTransition } from "./main--CpqrD_-.js";
import { S as SettingsRowV2, a as Switch } from "./row-CQ0pMN8i.js";
import { u as useUpdaterAction, S as SettingsKeybinds } from "./settings-keybinds-1JWVAFPD.js";
import { E as ExternalLink, u as useProviderConnectController, a as DialogCustomProvider, D as DialogConnectProvider } from "./dialog-connect-provider-CSAzTPRb.js";
import { S as SettingsListV2 } from "./list-cap7HycK.js";
import "./LROKH5N7-DNLoZdIV.js";
var _tmpl$$a = /* @__PURE__ */ template(`<span class="inline-flex items-center gap-2"data-slot=tabs-v2-trigger-content>`), _tmpl$2$7 = /* @__PURE__ */ template(`<div data-slot=tabs-v2-trigger-wrapper>`), _tmpl$3$7 = /* @__PURE__ */ template(`<span data-slot=tabs-v2-subtext class="ms-2 text-xs text-text-weak">`), _tmpl$4$7 = /* @__PURE__ */ template(`<div role=button tabindex=0 data-slot=tabs-v2-close-button><svg width=14 height=14 viewBox="0 0 14 14"fill=none xmlns=http://www.w3.org/2000/svg><path d="M10.8889 3.11108L3.11108 10.8889"stroke=currentColor stroke-linejoin=round></path><path d="M3.11108 3.11108L10.8889 10.8889"stroke=currentColor stroke-linejoin=round>`), _tmpl$5$5 = /* @__PURE__ */ template(`<div data-slot=tabs-v2-section-title>`);
function TabsV2Root(props) {
  const [split, rest] = splitProps(props, ["class", "classList", "variant", "orientation"]);
  return createComponent(Tabs, mergeProps(rest, {
    get orientation() {
      return split.orientation;
    },
    "data-component": "tabs-v2",
    get ["data-variant"]() {
      return split.variant || "normal";
    },
    get ["data-orientation"]() {
      return split.orientation || "horizontal";
    },
    get classList() {
      return {
        ...split.classList,
        [split.class ?? ""]: !!split.class
      };
    }
  }));
}
function TabsV2List(props) {
  const [split, rest] = splitProps(props, ["class", "classList"]);
  return createComponent(Tabs.List, mergeProps(rest, {
    "data-slot": "tabs-v2-list",
    get classList() {
      return {
        ...split.classList,
        [split.class ?? ""]: !!split.class
      };
    }
  }));
}
function TabsV2Trigger(props) {
  const [split, rest] = splitProps(props, ["class", "classList", "children", "onMiddleClick", "subtext"]);
  return (() => {
    var _el$ = _tmpl$2$7();
    _el$.addEventListener("auxclick", (e) => {
      if (e.button === 1 && split.onMiddleClick) {
        e.preventDefault();
        split.onMiddleClick();
      }
    });
    _el$.$$mousedown = (e) => {
      if (e.button === 1 && split.onMiddleClick) {
        e.preventDefault();
      }
    };
    insert(_el$, createComponent(Tabs.Trigger, mergeProps(rest, {
      "data-slot": "tabs-v2-trigger",
      get ["data-value"]() {
        return props.value;
      },
      get children() {
        var _el$2 = _tmpl$$a();
        insert(_el$2, () => split.children, null);
        insert(_el$2, createComponent(Show, {
          get when() {
            return split.subtext;
          },
          children: (subtext) => (() => {
            var _el$3 = _tmpl$3$7();
            insert(_el$3, subtext);
            return _el$3;
          })()
        }), null);
        return _el$2;
      }
    })));
    createRenderEffect((_p$) => {
      var _v$ = props.value, _v$2 = {
        ...split.classList,
        [split.class ?? ""]: !!split.class
      };
      _v$ !== _p$.e && setAttribute(_el$, "data-value", _p$.e = _v$);
      _p$.t = classList(_el$, _v$2, _p$.t);
      return _p$;
    }, {
      e: void 0,
      t: void 0
    });
    return _el$;
  })();
}
function TabsV2CloseButton(props) {
  const i18n = useI18n();
  const [split, rest] = splitProps(props, ["class", "classList", "onClick"]);
  return (() => {
    var _el$4 = _tmpl$4$7();
    spread(_el$4, mergeProps({
      get ["aria-label"]() {
        return i18n.t("ui.tabs.close");
      }
    }, rest, {
      get classList() {
        return {
          [split.class ?? ""]: !!split.class,
          ...split.classList
        };
      },
      "onClick": (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (typeof split.onClick === "function") {
          split.onClick(e);
        }
      },
      "onMouseDown": (e) => {
        e.preventDefault();
        e.stopPropagation();
      }
    }), false, true);
    return _el$4;
  })();
}
function TabsV2Content(props) {
  const [split, rest] = splitProps(props, ["class", "classList", "children"]);
  return createComponent(Tabs.Content, mergeProps(rest, {
    "data-slot": "tabs-v2-content",
    get classList() {
      return {
        ...split.classList,
        [split.class ?? ""]: !!split.class
      };
    },
    get children() {
      return split.children;
    }
  }));
}
const TabsV2SectionTitle = (props) => {
  return (() => {
    var _el$5 = _tmpl$5$5();
    insert(_el$5, () => props.children);
    return _el$5;
  })();
};
const TabsV2 = Object.assign(TabsV2Root, {
  List: TabsV2List,
  Trigger: TabsV2Trigger,
  CloseButton: TabsV2CloseButton,
  Content: TabsV2Content,
  SectionTitle: TabsV2SectionTitle
});
delegateEvents(["mousedown"]);
var _tmpl$$9 = /* @__PURE__ */ template(`<div data-action=settings-new-layout-designs>`), _tmpl$2$6 = /* @__PURE__ */ template(`<div class=settings-v2-section><div class=settings-v2-interface-feature>`), _tmpl$3$6 = /* @__PURE__ */ template(`<span class="flex items-center gap-2">`), _tmpl$4$6 = /* @__PURE__ */ template(`<div class=settings-v2-section>`);
function LayoutTransitionToggle(props) {
  return (() => {
    var _el$ = _tmpl$2$6(), _el$2 = _el$.firstChild;
    insert(_el$2, createComponent(SettingsListV2, {
      get children() {
        return createComponent(SettingsRowV2, {
          get title() {
            return (() => {
              var _el$4 = _tmpl$3$6();
              insert(_el$4, () => props.title, null);
              insert(_el$4, createComponent(Tag, {
                variant: "accent",
                get children() {
                  return props.badge;
                }
              }), null);
              return _el$4;
            })();
          },
          get description() {
            return props.description;
          },
          get children() {
            var _el$3 = _tmpl$$9();
            insert(_el$3, createComponent(Switch, {
              get checked() {
                return props.checked;
              },
              get onChange() {
                return props.onChange;
              }
            }));
            return _el$3;
          }
        });
      }
    }));
    return _el$;
  })();
}
function LayoutRetirementNotice(props) {
  return (() => {
    var _el$5 = _tmpl$4$6();
    insert(_el$5, createComponent(SettingsListV2, {
      get children() {
        return createComponent(SettingsRowV2, {
          get title() {
            return props.title;
          },
          get description() {
            return props.description;
          },
          get children() {
            return createComponent(ButtonV2, {
              size: "small",
              variant: "ghost-muted",
              get onClick() {
                return props.onDismiss;
              },
              get children() {
                return props.dismiss;
              }
            });
          }
        });
      }
    }));
    return _el$5;
  })();
}
function createShellOptions(input) {
  const counts = input.shells.reduce((result, shell) => {
    result.set(shell.name, (result.get(shell.name) ?? 0) + 1);
    return result;
  }, /* @__PURE__ */ new Map());
  const options = [
    { id: "auto", value: "", name: "", terminalOnly: false },
    ...input.shells.map((shell) => {
      const ambiguous = (counts.get(shell.name) ?? 0) > 1;
      const name = ambiguous ? shell.path : shell.name;
      return {
        id: shell.path,
        value: ambiguous ? shell.path : shell.name,
        name,
        terminalOnly: !shell.acceptable
      };
    })
  ];
  if (input.current && !options.some((option) => option.value === input.current)) {
    options.push({ id: input.current, value: input.current, name: input.current, terminalOnly: false });
  }
  return options;
}
function createSoundPreviewController(player) {
  let cleanup;
  let timeout;
  let run = 0;
  const stop = () => {
    run += 1;
    cleanup?.();
    clearTimeout(timeout);
    cleanup = void 0;
    timeout = void 0;
  };
  const play = (id) => {
    stop();
    if (!id) return;
    const current = ++run;
    timeout = setTimeout(() => {
      timeout = void 0;
      void player(id).then((next) => {
        if (run === current) {
          cleanup = next;
          return;
        }
        next?.();
      });
    }, 100);
  };
  onCleanup(stop);
  return { play, stop };
}
function createPermissionScopeController(sessionID) {
  const permission = usePermission();
  const serverSync = useServerSync();
  const directory = createMemo(() => {
    const id = sessionID();
    if (!id) return void 0;
    return serverSync().session.lineage.peek(id)?.session.directory;
  });
  return {
    accepting: createMemo(() => {
      const id = sessionID();
      const dir = directory();
      if (!id || !dir) return false;
      return permission.isAutoAccepting(id, dir);
    }),
    enabled: createMemo(() => !!directory()),
    set: (checked) => {
      const id = sessionID();
      const dir = directory();
      if (!id || !dir) return;
      if (checked) return permission.enableAutoAccept(id, dir);
      permission.disableAutoAccept(id, dir);
    }
  };
}
function createShellSettingsController() {
  const serverSdk = useServerSDK();
  const serverSync = useServerSync();
  const [shells] = createResource(
    async () => {
      const sdk = serverSdk();
      if (await sdk.protocol === "v1") return (await sdk.client.pty.shells()).data ?? [];
      return [];
    },
    { initialValue: [] }
  );
  const current = createMemo(() => serverSync().data.config.shell ?? "");
  return {
    shells: () => shells.latest,
    current,
    select: (value) => {
      if (value === current()) return;
      void serverSync().updateConfig({ shell: value });
    }
  };
}
function createAppearanceSettingsController() {
  const settings = useSettings();
  const theme = useTheme();
  const themes = createMemo(() => theme.ids().map((id) => ({ id, name: theme.name(id) })));
  onMount(() => void theme.loadThemes());
  return {
    scheme: {
      current: theme.colorScheme,
      select: (value) => theme.setColorScheme(value)
    },
    theme: {
      options: themes,
      current: createMemo(() => themes().find((option) => option.id === theme.themeId())),
      select: (option) => option && theme.setTheme(option.id)
    },
    fonts: {
      ui: createMemo(() => ({
        value: sansInput(settings.appearance.uiFont()),
        family: sansFontFamily(settings.appearance.uiFont()),
        placeholder: sansDefault
      })),
      code: createMemo(() => ({
        value: monoInput(settings.appearance.font()),
        family: monoFontFamily(settings.appearance.font()),
        placeholder: monoDefault
      })),
      terminal: createMemo(() => ({
        value: terminalInput(settings.appearance.terminalFont()),
        family: terminalFontFamily(settings.appearance.terminalFont()),
        placeholder: terminalDefault
      })),
      setUI: (value) => settings.appearance.setUIFont(value),
      setCode: (value) => settings.appearance.setFont(value),
      setTerminal: (value) => settings.appearance.setTerminalFont(value)
    }
  };
}
const noneSound = { id: "none", label: "sound.option.none" };
const soundOptions = [noneSound, ...SOUND_OPTIONS];
function createSoundSettingsController() {
  const settings = useSettings();
  const preview = createSoundPreviewController(playSoundById);
  const channel = (enabled, current, setEnabled, set) => ({
    current: createMemo(
      () => enabled() ? soundOptions.find((option) => option.id === current()) ?? noneSound : noneSound
    ),
    highlight: (option) => {
      if (!option) return;
      preview.play(option.id === "none" ? void 0 : option.id);
    },
    select: (option) => {
      if (!option) return;
      if (option.id === "none") {
        setEnabled(false);
        preview.stop();
        return;
      }
      setEnabled(true);
      set(option.id);
      preview.play(option.id);
    }
  });
  return {
    agent: channel(
      settings.sounds.agentEnabled,
      settings.sounds.agent,
      (value) => settings.sounds.setAgentEnabled(value),
      (id) => settings.sounds.setAgent(id)
    ),
    permissions: channel(
      settings.sounds.permissionsEnabled,
      settings.sounds.permissions,
      (value) => settings.sounds.setPermissionsEnabled(value),
      (id) => settings.sounds.setPermissions(id)
    ),
    errors: channel(
      settings.sounds.errorsEnabled,
      settings.sounds.errors,
      (value) => settings.sounds.setErrorsEnabled(value),
      (id) => settings.sounds.setErrors(id)
    )
  };
}
var _tmpl$$8 = /* @__PURE__ */ template(`<div data-action=settings-auto-accept-permissions>`), _tmpl$2$5 = /* @__PURE__ */ template(`<div class=settings-v2-section><h3 class=settings-v2-section-title>`), _tmpl$3$5 = /* @__PURE__ */ template(`<div class="w-full sm:w-[220px]">`), _tmpl$4$5 = /* @__PURE__ */ template(`<div data-action=settings-feed-reasoning-summaries>`), _tmpl$5$4 = /* @__PURE__ */ template(`<div data-action=settings-feed-shell-tool-parts-expanded>`), _tmpl$6$4 = /* @__PURE__ */ template(`<div data-action=settings-feed-edit-tool-parts-expanded>`), _tmpl$7$3 = /* @__PURE__ */ template(`<div data-action=settings-mobile-titlebar-bottom>`), _tmpl$8$3 = /* @__PURE__ */ template(`<div class=settings-v2-section>`), _tmpl$9$2 = /* @__PURE__ */ template(`<div data-action=settings-show-file-tree>`), _tmpl$0$1 = /* @__PURE__ */ template(`<div data-action=settings-show-search>`), _tmpl$1 = /* @__PURE__ */ template(`<div data-action=settings-show-status>`), _tmpl$10 = /* @__PURE__ */ template(`<div data-action=settings-show-custom-agents>`), _tmpl$11 = /* @__PURE__ */ template(`<div data-action=settings-notifications-agent>`), _tmpl$12 = /* @__PURE__ */ template(`<div data-action=settings-notifications-permissions>`), _tmpl$13 = /* @__PURE__ */ template(`<div data-action=settings-notifications-errors>`), _tmpl$14 = /* @__PURE__ */ template(`<div data-action=settings-release-notes>`), _tmpl$15 = /* @__PURE__ */ template(`<div data-action=settings-pinch-zoom>`), _tmpl$16 = /* @__PURE__ */ template(`<div class=settings-v2-tab-header><h2 class=settings-v2-tab-title>`), _tmpl$17 = /* @__PURE__ */ template(`<div class=settings-v2-tab-body>`);
const schemeOptions = ["system", "light", "dark"];
const fontSettings = {
  ui: {
    action: "settings-ui-font",
    title: "settings.general.row.uiFont.title",
    description: "settings.general.row.uiFont.description",
    font: "ui",
    input: "setUI"
  },
  code: {
    action: "settings-code-font",
    title: "settings.general.row.font.title",
    description: "settings.general.row.font.description",
    font: "code",
    input: "setCode"
  },
  terminal: {
    action: "settings-terminal-font",
    title: "settings.general.row.terminalFont.title",
    description: "settings.general.row.terminalFont.description",
    font: "terminal",
    input: "setTerminal"
  }
};
const soundSettings = {
  agent: {
    action: "settings-sounds-agent",
    title: "settings.general.sounds.agent.title",
    description: "settings.general.sounds.agent.description"
  },
  permissions: {
    action: "settings-sounds-permissions",
    title: "settings.general.sounds.permissions.title",
    description: "settings.general.sounds.permissions.description"
  },
  errors: {
    action: "settings-sounds-errors",
    title: "settings.general.sounds.errors.title",
    description: "settings.general.sounds.errors.description"
  }
};
const PermissionScopeSetting = (props) => {
  const language = useLanguage();
  return createComponent(SettingsRowV2, {
    get title() {
      return language.t("command.permissions.autoaccept.enable");
    },
    get description() {
      return language.t("toast.permissions.autoaccept.on.description");
    },
    get children() {
      var _el$ = _tmpl$$8();
      insert(_el$, createComponent(Switch, {
        get checked() {
          return props.controller.accepting();
        },
        get disabled() {
          return !props.controller.enabled();
        },
        get onChange() {
          return props.controller.set;
        }
      }));
      return _el$;
    }
  });
};
const ShellSetting = (props) => {
  const language = useLanguage();
  const options = createMemo(() => createShellOptions({
    shells: props.controller.shells(),
    current: props.controller.current()
  }));
  return createComponent(SettingsRowV2, {
    get title() {
      return language.t("settings.general.row.shell.title");
    },
    get description() {
      return language.t("settings.general.row.shell.description");
    },
    get children() {
      return createComponent(SelectV2, {
        appearance: "inline",
        "data-action": "settings-shell",
        get options() {
          return options();
        },
        get current() {
          return options().find((option) => option.value === props.controller.current()) ?? options()[0];
        },
        placement: "bottom-end",
        gutter: 6,
        value: (option) => option.id,
        label: (option) => {
          if (option.id === "auto") return language.t("settings.general.row.shell.autoDefault");
          if (!option.terminalOnly) return option.name;
          return `${option.name} (${language.t("settings.general.row.shell.terminalOnly")})`;
        },
        onSelect: (option) => option && props.controller.select(option.value)
      });
    }
  });
};
const AppearanceSection = (props) => {
  const language = useLanguage();
  return (() => {
    var _el$2 = _tmpl$2$5(), _el$3 = _el$2.firstChild;
    insert(_el$3, () => language.t("settings.general.section.appearance"));
    insert(_el$2, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.colorScheme.title");
          },
          get description() {
            return language.t("settings.general.row.colorScheme.description");
          },
          get children() {
            return createComponent(SelectV2, {
              appearance: "inline",
              "data-action": "settings-color-scheme",
              options: schemeOptions,
              get current() {
                return schemeOptions.find((option) => option === props.controller.scheme.current());
              },
              placement: "bottom-end",
              gutter: 6,
              label: (option) => {
                if (option === "system") return language.t("theme.scheme.system");
                if (option === "light") return language.t("theme.scheme.light");
                return language.t("theme.scheme.dark");
              },
              onSelect: (option) => option && props.controller.scheme.select(option)
            });
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.theme.title");
          },
          get description() {
            return [memo(() => language.t("settings.general.row.theme.description")), " ", createComponent(ExternalLink, {
              "class": "settings-v2-link",
              href: "https://opencode.ai/docs/themes/",
              get children() {
                return language.t("common.learnMore");
              }
            })];
          },
          get children() {
            return createComponent(SelectV2, {
              appearance: "inline",
              "data-action": "settings-theme",
              get options() {
                return props.controller.theme.options();
              },
              get current() {
                return props.controller.theme.current();
              },
              placement: "bottom-end",
              gutter: 6,
              value: (option) => option.id,
              label: (option) => option.name,
              get onSelect() {
                return props.controller.theme.select;
              }
            });
          }
        }), createComponent(FontSetting, {
          kind: "ui",
          get fonts() {
            return props.controller.fonts;
          }
        }), createComponent(FontSetting, {
          kind: "code",
          get fonts() {
            return props.controller.fonts;
          }
        }), createComponent(FontSetting, {
          kind: "terminal",
          get fonts() {
            return props.controller.fonts;
          }
        })];
      }
    }), null);
    return _el$2;
  })();
};
const FontSetting = (props) => {
  const language = useLanguage();
  const config = () => fontSettings[props.kind];
  return createComponent(SettingsRowV2, {
    get title() {
      return language.t(config().title);
    },
    get description() {
      return language.t(config().description);
    },
    get children() {
      var _el$4 = _tmpl$3$5();
      insert(_el$4, createComponent(TextInputV2, {
        get ["data-action"]() {
          return config().action;
        },
        type: "text",
        appearance: "base",
        get value() {
          return props.fonts[config().font]().value;
        },
        onInput: (event) => props.fonts[config().input](event.currentTarget.value),
        get placeholder() {
          return props.fonts[config().font]().placeholder;
        },
        spellcheck: false,
        autocorrect: "off",
        autocomplete: "off",
        autocapitalize: "off",
        get ["aria-label"]() {
          return language.t(config().title);
        },
        get style() {
          return {
            "font-family": props.fonts[config().font]().family
          };
        }
      }));
      return _el$4;
    }
  });
};
const SoundsSection = (props) => {
  const language = useLanguage();
  return (() => {
    var _el$5 = _tmpl$2$5(), _el$6 = _el$5.firstChild;
    insert(_el$6, () => language.t("settings.general.section.sounds"));
    insert(_el$5, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(SoundSetting, {
          kind: "agent",
          get channel() {
            return props.controller.agent;
          }
        }), createComponent(SoundSetting, {
          kind: "permissions",
          get channel() {
            return props.controller.permissions;
          }
        }), createComponent(SoundSetting, {
          kind: "errors",
          get channel() {
            return props.controller.errors;
          }
        })];
      }
    }), null);
    return _el$5;
  })();
};
const SoundSetting = (props) => {
  const language = useLanguage();
  const config = () => soundSettings[props.kind];
  return createComponent(SettingsRowV2, {
    get title() {
      return language.t(config().title);
    },
    get description() {
      return language.t(config().description);
    },
    get children() {
      return createComponent(SelectV2, {
        appearance: "inline",
        get ["data-action"]() {
          return config().action;
        },
        options: soundOptions,
        get current() {
          return props.channel.current();
        },
        value: (option) => option.id,
        label: (option) => language.t(option.label),
        get onHighlight() {
          return props.channel.highlight;
        },
        get onSelect() {
          return props.channel.select;
        },
        placement: "bottom-end",
        gutter: 6
      });
    }
  });
};
const LanguageSetting = () => {
  const language = useLanguage();
  const options = createMemo(() => language.locales.map((locale) => ({
    value: locale,
    label: language.label(locale)
  })));
  return createComponent(SettingsRowV2, {
    get title() {
      return language.t("settings.general.row.language.title");
    },
    get description() {
      return language.t("settings.general.row.language.description");
    },
    get children() {
      return createComponent(SelectV2, {
        appearance: "inline",
        "data-action": "settings-language",
        get options() {
          return options();
        },
        placement: "bottom-end",
        gutter: 6,
        get current() {
          return options().find((option) => option.value === language.locale());
        },
        value: (option) => option.value,
        label: (option) => option.label,
        onSelect: (option) => option && language.setLocale(option.value)
      });
    }
  });
};
const SettingsGeneralV2 = (props) => {
  const language = useLanguage();
  const platform = usePlatform();
  const dialog = useDialog();
  const settings = useSettings();
  const mobile = createMediaQuery("(max-width: 767px)");
  const updater = useUpdaterAction();
  const permissionScope = createPermissionScopeController(() => props.sessionID);
  const shell = createShellSettingsController();
  const appearance = createAppearanceSettingsController();
  const sounds = createSoundSettingsController();
  const desktop = createMemo(() => platform.platform === "desktop");
  const [pinchZoom, {
    mutate: setPinchZoom
  }] = createResource(() => desktop() && "getPinchZoomEnabled" in platform, () => Promise.resolve(platform.getPinchZoomEnabled?.() ?? false).catch(() => false), {
    initialValue: false
  });
  const onPinchZoomChange = (checked) => {
    setPinchZoom(checked);
    const update = platform.setPinchZoomEnabled?.(checked);
    if (!update) return;
    void update.catch(() => setPinchZoom(!checked));
  };
  const InterfaceSection = () => createComponent(LayoutTransitionToggle, {
    get title() {
      return language.t("settings.general.row.newInterface.title");
    },
    get badge() {
      return language.t("settings.general.row.newInterface.badge");
    },
    get description() {
      return language.t("settings.general.row.newInterface.description");
    },
    get checked() {
      return settings.general.newLayoutDesigns();
    },
    onChange: (checked) => {
      settings.general.setNewLayoutDesigns(checked);
      if (checked) return;
      void __vitePreload(() => import("./dialog-settings-DmYK2SOV.js"), true ? __vite__mapDeps([0,1,2,3,4,5,6,7]) : void 0, import.meta.url).then((module) => {
        void dialog.show(() => createComponent(module.DialogSettings, {}));
      });
    }
  });
  const InterfaceNoticeSection = () => createComponent(LayoutRetirementNotice, {
    get title() {
      return language.t("settings.general.row.newInterfaceNotice.title");
    },
    get description() {
      return language.t("settings.general.row.newInterfaceNotice.description");
    },
    get dismiss() {
      return language.t("settings.general.row.newInterfaceNotice.dismiss");
    },
    onDismiss: () => settings.general.dismissNewInterfaceNotice()
  });
  const GeneralSection = () => (() => {
    var _el$7 = _tmpl$8$3();
    insert(_el$7, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(LanguageSetting, {}), createComponent(PermissionScopeSetting, {
          controller: permissionScope
        }), createComponent(ShellSetting, {
          controller: shell
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.reasoningSummaries.title");
          },
          get description() {
            return language.t("settings.general.row.reasoningSummaries.description");
          },
          get children() {
            var _el$8 = _tmpl$4$5();
            insert(_el$8, createComponent(Switch, {
              get checked() {
                return settings.general.showReasoningSummaries();
              },
              onChange: (checked) => settings.general.setShowReasoningSummaries(checked)
            }));
            return _el$8;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.shellToolPartsExpanded.title");
          },
          get description() {
            return language.t("settings.general.row.shellToolPartsExpanded.description");
          },
          get children() {
            var _el$9 = _tmpl$5$4();
            insert(_el$9, createComponent(Switch, {
              get checked() {
                return settings.general.shellToolPartsExpanded();
              },
              onChange: (checked) => settings.general.setShellToolPartsExpanded(checked)
            }));
            return _el$9;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.editToolPartsExpanded.title");
          },
          get description() {
            return language.t("settings.general.row.editToolPartsExpanded.description");
          },
          get children() {
            var _el$0 = _tmpl$6$4();
            insert(_el$0, createComponent(Switch, {
              get checked() {
                return settings.general.editToolPartsExpanded();
              },
              onChange: (checked) => settings.general.setEditToolPartsExpanded(checked)
            }));
            return _el$0;
          }
        }), createComponent(Show, {
          get when() {
            return memo(() => !!mobile())() && false;
          },
          get children() {
            return createComponent(SettingsRowV2, {
              get title() {
                return language.t("settings.general.row.mobileTitlebarBottom.title");
              },
              get description() {
                return language.t("settings.general.row.mobileTitlebarBottom.description");
              },
              get children() {
                var _el$1 = _tmpl$7$3();
                insert(_el$1, createComponent(Switch, {
                  get checked() {
                    return settings.general.mobileTitlebarPosition() === "bottom";
                  },
                  onChange: (checked) => settings.general.setMobileTitlebarPosition(checked ? "bottom" : "top")
                }));
                return _el$1;
              }
            });
          }
        })];
      }
    }));
    return _el$7;
  })();
  const AdvancedSection = () => (() => {
    var _el$10 = _tmpl$2$5(), _el$11 = _el$10.firstChild;
    insert(_el$11, () => language.t("settings.general.section.advanced"));
    insert(_el$10, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.showFileTree.title");
          },
          get description() {
            return language.t("settings.general.row.showFileTree.description");
          },
          get children() {
            var _el$12 = _tmpl$9$2();
            insert(_el$12, createComponent(Switch, {
              get checked() {
                return settings.general.showFileTree();
              },
              onChange: (checked) => settings.general.setShowFileTree(checked)
            }));
            return _el$12;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.showSearch.title");
          },
          get description() {
            return language.t("settings.general.row.showSearch.description");
          },
          get children() {
            var _el$13 = _tmpl$0$1();
            insert(_el$13, createComponent(Switch, {
              get checked() {
                return settings.general.showSearch();
              },
              onChange: (checked) => settings.general.setShowSearch(checked)
            }));
            return _el$13;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.showStatus.title");
          },
          get description() {
            return language.t("settings.general.row.showStatus.description");
          },
          get children() {
            var _el$14 = _tmpl$1();
            insert(_el$14, createComponent(Switch, {
              get checked() {
                return settings.general.showStatus();
              },
              onChange: (checked) => settings.general.setShowStatus(checked)
            }));
            return _el$14;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.showCustomAgents.title");
          },
          get description() {
            return language.t("settings.general.row.showCustomAgents.description");
          },
          get children() {
            var _el$15 = _tmpl$10();
            insert(_el$15, createComponent(Switch, {
              get checked() {
                return settings.general.showCustomAgents();
              },
              onChange: (checked) => settings.general.setShowCustomAgents(checked)
            }));
            return _el$15;
          }
        })];
      }
    }), null);
    return _el$10;
  })();
  const NotificationsSection = () => (() => {
    var _el$16 = _tmpl$2$5(), _el$17 = _el$16.firstChild;
    insert(_el$17, () => language.t("settings.general.section.notifications"));
    insert(_el$16, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.notifications.agent.title");
          },
          get description() {
            return language.t("settings.general.notifications.agent.description");
          },
          get children() {
            var _el$18 = _tmpl$11();
            insert(_el$18, createComponent(Switch, {
              get checked() {
                return settings.notifications.agent();
              },
              onChange: (checked) => settings.notifications.setAgent(checked)
            }));
            return _el$18;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.notifications.permissions.title");
          },
          get description() {
            return language.t("settings.general.notifications.permissions.description");
          },
          get children() {
            var _el$19 = _tmpl$12();
            insert(_el$19, createComponent(Switch, {
              get checked() {
                return settings.notifications.permissions();
              },
              onChange: (checked) => settings.notifications.setPermissions(checked)
            }));
            return _el$19;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.notifications.errors.title");
          },
          get description() {
            return language.t("settings.general.notifications.errors.description");
          },
          get children() {
            var _el$20 = _tmpl$13();
            insert(_el$20, createComponent(Switch, {
              get checked() {
                return settings.notifications.errors();
              },
              onChange: (checked) => settings.notifications.setErrors(checked)
            }));
            return _el$20;
          }
        })];
      }
    }), null);
    return _el$16;
  })();
  const UpdatesSection = () => (() => {
    var _el$21 = _tmpl$2$5(), _el$22 = _el$21.firstChild;
    insert(_el$22, () => language.t("settings.general.section.updates"));
    insert(_el$21, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.general.row.releaseNotes.title");
          },
          get description() {
            return language.t("settings.general.row.releaseNotes.description");
          },
          get children() {
            var _el$23 = _tmpl$14();
            insert(_el$23, createComponent(Switch, {
              get checked() {
                return settings.general.releaseNotes();
              },
              onChange: (checked) => settings.general.setReleaseNotes(checked)
            }));
            return _el$23;
          }
        }), createComponent(SettingsRowV2, {
          get title() {
            return language.t("settings.updates.row.check.title");
          },
          get description() {
            return language.t("settings.updates.row.check.description");
          },
          get children() {
            return createComponent(ButtonV2, {
              size: "normal",
              variant: "neutral",
              get disabled() {
                return !updater.action().run;
              },
              onClick: () => updater.run(),
              get children() {
                return language.t(updater.action().label);
              }
            });
          }
        })];
      }
    }), null);
    return _el$21;
  })();
  const DisplaySection = () => createComponent(Show, {
    get when() {
      return desktop();
    },
    get children() {
      var _el$24 = _tmpl$2$5(), _el$25 = _el$24.firstChild;
      insert(_el$25, () => language.t("settings.general.section.display"));
      insert(_el$24, createComponent(SettingsListV2, {
        get children() {
          return createComponent(SettingsRowV2, {
            get title() {
              return language.t("settings.general.row.pinchZoom.title");
            },
            get description() {
              return language.t("settings.general.row.pinchZoom.description");
            },
            get children() {
              var _el$26 = _tmpl$15();
              insert(_el$26, createComponent(Switch, {
                get checked() {
                  return pinchZoom.latest;
                },
                onChange: onPinchZoomChange
              }));
              return _el$26;
            }
          });
        }
      }), null);
      return _el$24;
    }
  });
  return [(() => {
    var _el$27 = _tmpl$16(), _el$28 = _el$27.firstChild;
    insert(_el$28, () => language.t("settings.tab.general"));
    return _el$27;
  })(), (() => {
    var _el$29 = _tmpl$17();
    insert(_el$29, createComponent(Show, {
      get when() {
        return settings.general.layoutTransitionAvailable();
      },
      get children() {
        return createComponent(InterfaceSection, {});
      }
    }), null);
    insert(_el$29, createComponent(Show, {
      get when() {
        return settings.general.newInterfaceNoticeVisible();
      },
      get children() {
        return createComponent(InterfaceNoticeSection, {});
      }
    }), null);
    insert(_el$29, createComponent(GeneralSection, {}), null);
    insert(_el$29, createComponent(AppearanceSection, {
      controller: appearance
    }), null);
    insert(_el$29, createComponent(NotificationsSection, {}), null);
    insert(_el$29, createComponent(SoundsSection, {
      controller: sounds
    }), null);
    insert(_el$29, createComponent(Show, {
      get when() {
        return desktop();
      },
      get children() {
        return createComponent(UpdatesSection, {});
      }
    }), null);
    insert(_el$29, createComponent(DisplaySection, {}), null);
    insert(_el$29, createComponent(AdvancedSection, {}), null);
    return _el$29;
  })()];
};
var _tmpl$$7 = /* @__PURE__ */ template(`<div class=settings-v2-tab-header><h2 class=settings-v2-tab-title>`), _tmpl$2$4 = /* @__PURE__ */ template(`<div class=settings-v2-provider-row data-component=custom-provider-section><div class=settings-v2-provider-lead><div class=settings-v2-provider-copy><div class=settings-v2-provider-main><span class=settings-v2-provider-name></span></div><p class=settings-v2-provider-description>`), _tmpl$3$4 = /* @__PURE__ */ template(`<div class="settings-v2-tab-body settings-v2-providers"><div class=settings-v2-section data-component=connected-providers-section><h3 class=settings-v2-section-title></h3></div><div class=settings-v2-section><h3 class=settings-v2-section-title></h3><button type=button class=settings-v2-providers-view-all>`), _tmpl$4$4 = /* @__PURE__ */ template(`<div class=settings-v2-provider-empty>`), _tmpl$5$3 = /* @__PURE__ */ template(`<div class="settings-v2-provider-row group"><div class=settings-v2-provider-lead><div class=settings-v2-provider-main><span class="settings-v2-provider-name truncate">`), _tmpl$6$3 = /* @__PURE__ */ template(`<span class=settings-v2-provider-env-hint>`), _tmpl$7$2 = /* @__PURE__ */ template(`<div class=settings-v2-provider-row><div class=settings-v2-provider-lead><div class=settings-v2-provider-copy><div class=settings-v2-provider-main><span class=settings-v2-provider-name>`), _tmpl$8$2 = /* @__PURE__ */ template(`<p class=settings-v2-provider-description>`);
const PROVIDER_NOTES = [{
  match: (id) => id === "opencode",
  key: "dialog.provider.opencode.note"
}, {
  match: (id) => id === "opencode-go",
  key: "dialog.provider.opencodeGo.tagline"
}, {
  match: (id) => id === "anthropic",
  key: "dialog.provider.anthropic.note"
}, {
  match: (id) => id.startsWith("github-copilot"),
  key: "dialog.provider.copilot.note"
}, {
  match: (id) => id === "openai",
  key: "dialog.provider.openai.note"
}, {
  match: (id) => id === "google",
  key: "dialog.provider.google.note"
}, {
  match: (id) => id === "openrouter",
  key: "dialog.provider.openrouter.note"
}, {
  match: (id) => id === "vercel",
  key: "dialog.provider.vercel.note"
}];
const PROVIDER_ICON_SIZE$1 = 16;
const SettingsProvidersV2 = (props) => {
  const dialog = useDialog();
  const language = useLanguage();
  const serverSdk = useServerSDK();
  const protocol = useServerProtocol();
  const serverSync = useServerSync();
  const providers = useProviders(props.directory);
  const providerConnect = useProviderConnectController({
    onBack: props.onBack
  });
  const connect = (provider) => {
    providerConnect.select(provider);
    void dialog.show(() => createComponent(DialogConnectProvider, {
      get directory() {
        return props.directory;
      },
      controller: providerConnect
    }));
  };
  const connected = createMemo(() => {
    return providers.connected().filter((p) => p.id !== "opencode" || Object.values(p.models).find((m) => m.cost?.input));
  });
  const popular = createMemo(() => {
    const connectedIDs = new Set(connected().map((p) => p.id));
    const items = providers.popular().filter((p) => !connectedIDs.has(p.id)).slice();
    items.sort((a, b) => popularProviders.indexOf(a.id) - popularProviders.indexOf(b.id));
    return items;
  });
  const source = (item) => {
    if (!("source" in item)) return;
    const value = item.source;
    if (value === "env" || value === "api" || value === "config" || value === "custom") return value;
    return;
  };
  const type = (item) => {
    const current = source(item);
    if (current === "env") return language.t("settings.providers.tag.environment");
    if (current === "api") return language.t("provider.connect.method.apiKey");
    if (current === "config") {
      if (isConfigCustom(item.id)) return language.t("settings.providers.tag.custom");
      return language.t("settings.providers.tag.config");
    }
    if (current === "custom") return language.t("settings.providers.tag.custom");
    return language.t("settings.providers.tag.other");
  };
  const canDisconnect = (item) => source(item) !== "env" && (protocol() === "v1" || !isConfigCustom(item.id));
  const note = (id) => PROVIDER_NOTES.find((item) => item.match(id))?.key;
  const isConfigCustom = (providerID) => {
    const provider = serverSync().data.config.provider?.[providerID];
    if (!provider) return false;
    if (provider.npm !== "@ai-sdk/openai-compatible") return false;
    if (!provider.models || Object.keys(provider.models).length === 0) return false;
    return true;
  };
  const disableProvider = async (providerID, name) => {
    if (protocol() !== "v1") return;
    const before = serverSync().data.config.disabled_providers ?? [];
    const next = before.includes(providerID) ? before : [...before, providerID];
    serverSync().set("config", "disabled_providers", next);
    await serverSync().updateConfig({
      disabled_providers: next
    }).then(() => {
      showToast({
        variant: "success",
        icon: "circle-check",
        title: language.t("provider.disconnect.toast.disconnected.title", {
          provider: name
        }),
        description: language.t("provider.disconnect.toast.disconnected.description", {
          provider: name
        })
      });
    }).catch((err) => {
      serverSync().set("config", "disabled_providers", before);
      const message = err instanceof Error ? err.message : String(err);
      showToast({
        title: language.t("common.requestFailed"),
        description: message
      });
    });
  };
  const disconnect = async (providerID, name) => {
    if (isConfigCustom(providerID)) {
      await serverSdk().client.auth.remove({
        providerID
      }).catch(() => void 0);
      await disableProvider(providerID, name);
      return;
    }
    await serverSdk().client.auth.remove({
      providerID
    }).then(async () => {
      await serverSdk().client.global.dispose();
      showToast({
        variant: "success",
        icon: "circle-check",
        title: language.t("provider.disconnect.toast.disconnected.title", {
          provider: name
        }),
        description: language.t("provider.disconnect.toast.disconnected.description", {
          provider: name
        })
      });
    }).catch((err) => {
      const message = err instanceof Error ? err.message : String(err);
      showToast({
        title: language.t("common.requestFailed"),
        description: message
      });
    });
  };
  return [(() => {
    var _el$ = _tmpl$$7(), _el$2 = _el$.firstChild;
    insert(_el$2, () => language.t("settings.providers.title"));
    return _el$;
  })(), (() => {
    var _el$3 = _tmpl$3$4(), _el$4 = _el$3.firstChild, _el$5 = _el$4.firstChild, _el$6 = _el$4.nextSibling, _el$7 = _el$6.firstChild, _el$12 = _el$7.nextSibling;
    insert(_el$5, () => language.t("settings.providers.section.connected"));
    insert(_el$4, createComponent(SettingsListV2, {
      get children() {
        return createComponent(Show, {
          get when() {
            return connected().length > 0;
          },
          get fallback() {
            return (() => {
              var _el$13 = _tmpl$4$4();
              insert(_el$13, () => language.t("settings.providers.connected.empty"));
              return _el$13;
            })();
          },
          get children() {
            return createComponent(For, {
              get each() {
                return connected();
              },
              children: (item) => (() => {
                var _el$14 = _tmpl$5$3(), _el$15 = _el$14.firstChild, _el$16 = _el$15.firstChild, _el$17 = _el$16.firstChild;
                insert(_el$15, createComponent(ProviderIcon, {
                  get id() {
                    return item.id;
                  },
                  width: PROVIDER_ICON_SIZE$1,
                  height: PROVIDER_ICON_SIZE$1,
                  "class": "settings-v2-provider-icon shrink-0"
                }), _el$16);
                insert(_el$17, () => item.name);
                insert(_el$16, createComponent(Tag, {
                  get children() {
                    return type(item);
                  }
                }), null);
                insert(_el$14, createComponent(Show, {
                  get when() {
                    return canDisconnect(item);
                  },
                  get fallback() {
                    return (() => {
                      var _el$18 = _tmpl$6$3();
                      insert(_el$18, () => language.t("settings.providers.connected.environmentDescription"));
                      return _el$18;
                    })();
                  },
                  get children() {
                    return createComponent(ButtonV2, {
                      size: "normal",
                      variant: "ghost-muted",
                      onClick: () => void disconnect(item.id, item.name),
                      get children() {
                        return language.t("common.disconnect");
                      }
                    });
                  }
                }), null);
                return _el$14;
              })()
            });
          }
        });
      }
    }), null);
    insert(_el$7, () => language.t("settings.providers.section.popular"));
    insert(_el$6, createComponent(SettingsListV2, {
      get children() {
        return [createComponent(For, {
          get each() {
            return popular();
          },
          children: (item) => (() => {
            var _el$19 = _tmpl$7$2(), _el$20 = _el$19.firstChild, _el$21 = _el$20.firstChild, _el$22 = _el$21.firstChild, _el$23 = _el$22.firstChild;
            insert(_el$20, createComponent(ProviderIcon, {
              get id() {
                return item.id;
              },
              width: PROVIDER_ICON_SIZE$1,
              height: PROVIDER_ICON_SIZE$1,
              "class": "settings-v2-provider-icon shrink-0"
            }), _el$21);
            insert(_el$23, () => item.name);
            insert(_el$22, createComponent(Show, {
              get when() {
                return item.id === "opencode" || item.id === "opencode-go";
              },
              get children() {
                return createComponent(Tag, {
                  get children() {
                    return language.t("dialog.provider.tag.recommended");
                  }
                });
              }
            }), null);
            insert(_el$21, createComponent(Show, {
              get when() {
                return note(item.id);
              },
              children: (key) => (() => {
                var _el$24 = _tmpl$8$2();
                insert(_el$24, () => language.t(key()));
                return _el$24;
              })()
            }), null);
            insert(_el$19, createComponent(ButtonV2, {
              size: "normal",
              variant: "neutral",
              icon: "plus",
              onClick: () => connect(item.id),
              get children() {
                return language.t("common.connect");
              }
            }), null);
            return _el$19;
          })()
        }), createComponent(Show, {
          get when() {
            return protocol() === "v1";
          },
          get children() {
            var _el$8 = _tmpl$2$4(), _el$9 = _el$8.firstChild, _el$0 = _el$9.firstChild, _el$1 = _el$0.firstChild, _el$10 = _el$1.firstChild, _el$11 = _el$1.nextSibling;
            insert(_el$9, createComponent(ProviderIcon, {
              id: "synthetic",
              width: PROVIDER_ICON_SIZE$1,
              height: PROVIDER_ICON_SIZE$1,
              "class": "settings-v2-provider-icon shrink-0"
            }), _el$0);
            insert(_el$10, () => language.t("provider.custom.title"));
            insert(_el$1, createComponent(Tag, {
              get children() {
                return language.t("settings.providers.tag.custom");
              }
            }), null);
            insert(_el$11, () => language.t("settings.providers.custom.description"));
            insert(_el$8, createComponent(ButtonV2, {
              size: "normal",
              variant: "neutral",
              icon: "plus",
              onClick: () => {
                dialog.show(() => createComponent(DialogCustomProvider, {
                  get onBack() {
                    return dialog.close;
                  }
                }));
              },
              get children() {
                return language.t("common.connect");
              }
            }), null);
            return _el$8;
          }
        })];
      }
    }), _el$12);
    _el$12.$$click = () => connect();
    insert(_el$12, () => language.t("dialog.provider.viewAll"));
    return _el$3;
  })()];
};
delegateEvents(["click"]);
var _tmpl$$6 = /* @__PURE__ */ template(`<div class="settings-v2-tab-header settings-v2-tab-header--stacked"><h2 class=settings-v2-tab-title></h2><div class=settings-v2-tab-search>`), _tmpl$2$3 = /* @__PURE__ */ template(`<div class="settings-v2-tab-body settings-v2-models">`), _tmpl$3$3 = /* @__PURE__ */ template(`<div class=settings-v2-models-status>`), _tmpl$4$3 = /* @__PURE__ */ template(`<span class=settings-v2-models-status-filter>&quot;<!>&quot;`), _tmpl$5$2 = /* @__PURE__ */ template(`<div class=settings-v2-models-status><span>`), _tmpl$6$2 = /* @__PURE__ */ template(`<svg width=16 height=16 viewBox="0 0 16 16"fill=none aria-hidden=true><path d="M5.37624 6.75194C5.18184 6.41861 5.42224 6 5.80814 6H10.1921C10.578 6 10.8184 6.41861 10.624 6.75194L8.43203 10.5096C8.23909 10.8404 7.76119 10.8404 7.56825 10.5096L5.37624 6.75194Z"fill=currentColor>`), _tmpl$7$1 = /* @__PURE__ */ template(`<div class=settings-v2-section data-component=settings-models-provider><h3 class=settings-v2-models-group-header><button type=button class=settings-v2-models-group-trigger><span class=settings-v2-models-group-chevron></span><span class=settings-v2-models-group-label><span class=settings-v2-section-title>`), _tmpl$8$1 = /* @__PURE__ */ template(`<svg width=5 height=6 viewBox="0 0 5 6"fill=none aria-hidden=true><path d="M0.75194 5.31663C0.41861 5.51103 0 5.27063 0 4.88473V0.500754C0 0.114854 0.41861 -0.125577 0.75194 0.0688635L4.5096 2.26084C4.8404 2.45378 4.8404 2.93168 4.5096 3.12462L0.75194 5.31663Z"fill=currentColor>`), _tmpl$9$1 = /* @__PURE__ */ template(`<div>`);
const PROVIDER_ICON_SIZE = 16;
const SettingsModelsV2 = () => {
  const language = useLanguage();
  const models = useModels();
  const serverSdk = useServerSDK();
  const [store, setStore] = persisted(Persist.serverGlobal(serverSdk().scope, "settings-v2.models.providers"), createStore({
    collapsed: {}
  }));
  const list = useFilteredList({
    items: (_filter) => models.list(),
    key: (x) => `${x.provider.id}:${x.id}`,
    filterKeys: ["provider.name", "name", "id"],
    sortBy: (a, b) => a.name.localeCompare(b.name),
    groupBy: (x) => x.provider.id,
    sortGroupsBy: (a, b) => {
      const aIndex = popularProviders.indexOf(a.category);
      const bIndex = popularProviders.indexOf(b.category);
      const aPopular = aIndex >= 0;
      const bPopular = bIndex >= 0;
      if (aPopular && !bPopular) return -1;
      if (!aPopular && bPopular) return 1;
      if (aPopular && bPopular) return aIndex - bIndex;
      const aName = a.items[0].provider.name;
      const bName = b.items[0].provider.name;
      return aName.localeCompare(bName);
    }
  });
  return [(() => {
    var _el$ = _tmpl$$6(), _el$2 = _el$.firstChild, _el$3 = _el$2.nextSibling;
    insert(_el$2, () => language.t("settings.models.title"));
    insert(_el$3, createComponent(TextInputV2, {
      type: "search",
      appearance: "base",
      get value() {
        return list.filter();
      },
      onInput: (event) => list.onInput(event.currentTarget.value),
      get placeholder() {
        return language.t("dialog.model.search.placeholder");
      },
      spellcheck: false,
      autocorrect: "off",
      autocomplete: "off",
      autocapitalize: "off",
      get ["aria-label"]() {
        return language.t("dialog.model.search.placeholder");
      }
    }), null);
    insert(_el$3, createComponent(Show, {
      get when() {
        return list.filter();
      },
      get children() {
        return createComponent(IconButtonV2, {
          type: "button",
          variant: "ghost-muted",
          size: "small",
          "class": "settings-v2-tab-search-clear",
          get icon() {
            return createComponent(Icon, {
              name: "close",
              size: "large",
              "class": "text-v2-icon-icon-muted"
            });
          },
          onClick: () => list.clear()
        });
      }
    }), null);
    return _el$;
  })(), (() => {
    var _el$4 = _tmpl$2$3();
    insert(_el$4, createComponent(Show, {
      get when() {
        return !list.grouped.loading;
      },
      get fallback() {
        return (() => {
          var _el$5 = _tmpl$3$3();
          insert(_el$5, () => language.t("common.loading"), null);
          insert(_el$5, () => language.t("common.loading.ellipsis"), null);
          return _el$5;
        })();
      },
      get children() {
        return createComponent(Show, {
          get when() {
            return list.flat().length > 0;
          },
          get fallback() {
            return (() => {
              var _el$6 = _tmpl$5$2(), _el$7 = _el$6.firstChild;
              insert(_el$7, () => language.t("dialog.model.empty"));
              insert(_el$6, createComponent(Show, {
                get when() {
                  return list.filter();
                },
                get children() {
                  var _el$8 = _tmpl$4$3(), _el$9 = _el$8.firstChild, _el$1 = _el$9.nextSibling;
                  _el$1.nextSibling;
                  insert(_el$8, () => list.filter(), _el$1);
                  return _el$8;
                }
              }), null);
              return _el$6;
            })();
          },
          get children() {
            return createComponent(For, {
              get each() {
                return list.grouped.latest;
              },
              children: (group) => {
                const searching = () => list.filter().length > 0;
                const expanded = () => searching() || !store.collapsed[group.category];
                return (() => {
                  var _el$10 = _tmpl$7$1(), _el$11 = _el$10.firstChild, _el$12 = _el$11.firstChild, _el$13 = _el$12.firstChild, _el$15 = _el$13.nextSibling, _el$16 = _el$15.firstChild;
                  _el$12.$$click = () => setStore("collapsed", group.category, expanded());
                  insert(_el$13, createComponent(Show, {
                    get when() {
                      return expanded();
                    },
                    get fallback() {
                      return _tmpl$8$1();
                    },
                    get children() {
                      return _tmpl$6$2();
                    }
                  }));
                  insert(_el$15, createComponent(ProviderIcon, {
                    get id() {
                      return group.category;
                    },
                    width: PROVIDER_ICON_SIZE,
                    height: PROVIDER_ICON_SIZE,
                    "class": "settings-v2-models-provider-icon shrink-0"
                  }), _el$16);
                  insert(_el$16, () => group.items[0].provider.name);
                  insert(_el$10, createComponent(Show, {
                    get when() {
                      return expanded();
                    },
                    get children() {
                      return createComponent(SettingsListV2, {
                        get children() {
                          return createComponent(For, {
                            get each() {
                              return group.items;
                            },
                            children: (item) => {
                              const key = {
                                providerID: item.provider.id,
                                modelID: item.id
                              };
                              return createComponent(SettingsRowV2, {
                                get title() {
                                  return item.name;
                                },
                                description: "",
                                get children() {
                                  var _el$18 = _tmpl$9$1();
                                  insert(_el$18, createComponent(Switch, {
                                    get checked() {
                                      return models.visible(key);
                                    },
                                    onChange: (checked) => {
                                      models.setVisibility(key, checked);
                                    },
                                    hideLabel: true,
                                    get children() {
                                      return item.name;
                                    }
                                  }));
                                  return _el$18;
                                }
                              });
                            }
                          });
                        }
                      });
                    }
                  }), null);
                  createRenderEffect((_p$) => {
                    var _v$ = expanded() ? "" : void 0, _v$2 = expanded(), _v$3 = searching();
                    _v$ !== _p$.e && setAttribute(_el$10, "data-expanded", _p$.e = _v$);
                    _v$2 !== _p$.t && setAttribute(_el$12, "aria-expanded", _p$.t = _v$2);
                    _v$3 !== _p$.a && (_el$12.disabled = _p$.a = _v$3);
                    return _p$;
                  }, {
                    e: void 0,
                    t: void 0,
                    a: void 0
                  });
                  return _el$10;
                })();
              }
            });
          }
        });
      }
    }));
    return _el$4;
  })()];
};
delegateEvents(["click"]);
var _tmpl$$5 = /* @__PURE__ */ template(`<svg><circle cx=8 cy=8 r=6 data-slot=loader-v2-background stroke-width=2></circle><circle cx=8 cy=8 r=6 data-slot=loader-v2-progress pathLength=100 stroke-width=2 stroke-dasharray="33 67">`);
function LoaderV2(props) {
  const [local, rest] = splitProps(props, ["class", "classList", "width", "height"]);
  return (() => {
    var _el$ = _tmpl$$5();
    spread(_el$, mergeProps(rest, {
      get ["class"]() {
        return local.class;
      },
      get classList() {
        return local.classList;
      },
      get width() {
        return local.width ?? 16;
      },
      get height() {
        return local.height ?? 16;
      },
      "viewBox": "0 0 16 16",
      "fill": "none",
      "xmlns": "http://www.w3.org/2000/svg",
      "data-component": "loader-v2",
      get ["aria-hidden"]() {
        return rest["aria-hidden"] ?? "true";
      }
    }), true, true);
    return _el$;
  })();
}
var _tmpl$$4 = /* @__PURE__ */ template(`<div data-slot=radio-v2-items>`), _tmpl$2$2 = /* @__PURE__ */ template(`<div data-slot=radio-v2-item-control-stack>`), _tmpl$3$2 = /* @__PURE__ */ template(`<div data-slot=radio-v2-item-text><span data-slot=radio-v2-item-label-text>`), _tmpl$4$2 = /* @__PURE__ */ template(`<span data-slot=radio-v2-item-description>`);
function RadioGroupV2(props) {
  const [local, others] = splitProps(props, ["class", "classList", "children", "label", "description", "hideLabel"]);
  return createComponent(RadioGroup, mergeProps(others, {
    "data-component": "radio-v2",
    get classList() {
      return {
        ...local.classList,
        [local.class ?? ""]: !!local.class
      };
    },
    get children() {
      return [createComponent(Show, {
        get when() {
          return local.label;
        },
        children: (label) => createComponent(RadioGroup.Label, {
          "data-slot": "radio-v2-label",
          get classList() {
            return {
              "sr-only": local.hideLabel
            };
          },
          get children() {
            return label();
          }
        })
      }), createComponent(Show, {
        get when() {
          return local.description;
        },
        children: (description) => createComponent(RadioGroup.Description, {
          "data-slot": "radio-v2-description",
          get children() {
            return description();
          }
        })
      }), (() => {
        var _el$ = _tmpl$$4();
        insert(_el$, () => local.children);
        return _el$;
      })(), createComponent(RadioGroup.ErrorMessage, {
        "data-slot": "radio-v2-error"
      })];
    }
  }));
}
function RadioItemV2(props) {
  const [local, others] = splitProps(props, ["class", "classList", "label", "description", "hideLabel"]);
  return createComponent(RadioGroup.Item, mergeProps(others, {
    "data-slot": "radio-v2-item",
    get classList() {
      return {
        ...local.classList,
        [local.class ?? ""]: !!local.class
      };
    },
    get children() {
      return [createComponent(RadioGroup.ItemInput, {
        "data-slot": "radio-v2-item-input"
      }), (() => {
        var _el$2 = _tmpl$2$2();
        insert(_el$2, createComponent(RadioGroup.ItemControl, {
          "data-slot": "radio-v2-item-control",
          get children() {
            return createComponent(RadioGroup.ItemIndicator, {
              "data-slot": "radio-v2-item-indicator"
            });
          }
        }));
        return _el$2;
      })(), createComponent(RadioGroup.ItemLabel, {
        "data-slot": "radio-v2-item-label",
        get classList() {
          return {
            "sr-only": local.hideLabel
          };
        },
        get children() {
          var _el$3 = _tmpl$3$2(), _el$4 = _el$3.firstChild;
          insert(_el$4, () => local.label);
          insert(_el$3, createComponent(Show, {
            get when() {
              return local.description;
            },
            children: (description) => (() => {
              var _el$5 = _tmpl$4$2();
              insert(_el$5, description);
              return _el$5;
            })()
          }), null);
          return _el$3;
        }
      })];
    }
  }));
}
function isHiddenDistro(name) {
  return /^docker-desktop(?:-data)?$/i.test(name);
}
const wslRuntimeRetryable = (runtime) => runtime.kind === "failed" || runtime.kind === "stopped";
function wslOpencodeAction(check) {
  if (!check) return;
  if (!check.resolvedPath) return "wsl.onboarding.installOpencode";
  if (check.matchesDesktop === false) return "wsl.onboarding.updateOpencode";
}
function wslDistroReady(state, name) {
  const installed = state?.installed.find((item) => item.name === name);
  const probe = state?.distroProbes[name];
  if (!probe || !installed) return false;
  if (installed.version === 1) return false;
  return probe.canExecute && probe.hasBash && probe.hasCurl;
}
function addServerViewModel(input) {
  const state = input.state;
  const visibleInstalledDistros = (state?.installed ?? []).filter((item) => !isHiddenDistro(item.name));
  const visibleOnlineDistros = (state?.online ?? []).filter((item) => !isHiddenDistro(item.name));
  const existingServerDistros = new Set((state?.servers ?? []).map((item) => item.config.distro));
  const addableInstalledDistros = visibleInstalledDistros.filter((item) => !existingServerDistros.has(item.name));
  const selectedDistro = addServerSelectedDistro(input.selectedDistro, visibleInstalledDistros, addableInstalledDistros);
  const opencodeCheck = selectedDistro ? state?.opencodeChecks[selectedDistro] ?? null : null;
  const installableDistros = addServerInstallableDistros(visibleInstalledDistros, visibleOnlineDistros);
  const filteredInstallableDistros = addServerFilteredInstallableDistros(installableDistros, input.catalogSearch);
  const catalogTarget = addServerCatalogTarget(input.catalogTarget, filteredInstallableDistros);
  const busy = !!state?.job || input.adding || input.probingAddable;
  return {
    busy,
    runtimeState: addServerRuntimeState(state),
    visibleInstalledDistros,
    visibleOnlineDistros,
    addableInstalledDistros,
    selectedDistro,
    opencodeCheck,
    wslReady: !!state?.runtime?.available && !state?.pendingRestart,
    distroStatuses: Object.fromEntries(
      addableInstalledDistros.flatMap((item) => {
        const status = addServerDistroStatus({ state, name: item.name, probingAddable: input.probingAddable });
        if (!status) return [];
        return [[item.name, status]];
      })
    ),
    primaryButton: addServerPrimaryButton({
      state,
      selectedDistro,
      opencodeCheck,
      adding: input.adding,
      probingAddable: input.probingAddable
    }),
    installableDistros,
    filteredInstallableDistros,
    catalogTarget,
    installingCatalogDistro: state?.job?.kind === "install-distro"
  };
}
function addServerSelectedDistro(selected, visibleInstalledDistros, addableInstalledDistros) {
  if (selected && addableInstalledDistros.some((item) => item.name === selected && item.version !== 1)) return selected;
  const defaultDistro = visibleInstalledDistros.find((item) => item.isDefault);
  if (defaultDistro && defaultDistro.version !== 1 && addableInstalledDistros.some((item) => item.name === defaultDistro.name)) {
    return defaultDistro.name;
  }
  return addableInstalledDistros.find((item) => item.version !== 1)?.name ?? null;
}
function addServerRuntimeState(state) {
  if (!state) return "loading";
  if (state.pendingRestart) return "pendingRestart";
  if (!state.runtime) return "checking";
  if (!state.runtime.available) return "unavailable";
  return "ready";
}
function addServerDistroStatus(input) {
  const installed = input.state?.installed.find((item) => item.name === input.name);
  if (installed?.version === 1) return { label: { key: "wsl.onboarding.distroStatus.unsupported" }, tone: "muted" };
  const job = input.state?.job;
  const probe = input.state?.distroProbes[input.name];
  if (!probe) {
    if (input.probingAddable || job?.kind === "probe-addable" && job.distros.includes(input.name)) {
      return checkingStatus();
    }
    return;
  }
  if (!probe.canExecute) {
    if (!installed) {
      return { label: { key: "wsl.onboarding.distroNotInstalled", params: { distro: input.name } }, tone: "warning" };
    }
    return { label: { key: "wsl.onboarding.openDistroOnce", params: { distro: input.name } }, tone: "warning" };
  }
  if (!probe.hasBash || !probe.hasCurl) {
    return { label: { key: "wsl.onboarding.distroStatus.missingTools" }, tone: "warning" };
  }
  const check = input.state?.opencodeChecks[input.name];
  if (!check) {
    if (input.probingAddable || job?.kind === "probe-addable" && job.distros.includes(input.name)) {
      return checkingStatus();
    }
    return;
  }
  if (check.matchesDesktop === false) return { label: { key: "wsl.onboarding.updateOpencode" }, tone: "warning" };
  if (!check.resolvedPath) return { label: { key: "wsl.onboarding.distroStatus.opencodeMissing" }, tone: "warning" };
  if (check.error) return { label: { key: "wsl.onboarding.installOpencode" }, tone: "warning" };
  return { label: { key: "wsl.onboarding.distroStatus.ready" }, tone: "success" };
}
function checkingStatus() {
  return { label: { key: "wsl.onboarding.distroStatus.checking" }, tone: "muted" };
}
function addServerPrimaryButton(input) {
  const ready = !!input.selectedDistro && wslDistroReady(input.state, input.selectedDistro);
  const probingSelected = input.probingAddable && !addServerSelectedDistroSettled(input.state, input.selectedDistro);
  const probingOpencode = probingSelected || ready && (!input.opencodeCheck || !!input.selectedDistro && input.state?.job?.kind === "probe-addable" && input.state.job.distros.includes(input.selectedDistro));
  const installingOpencode = input.state?.job?.kind === "install-opencode" && input.state.job.distro === input.selectedDistro;
  if (!ready || probingOpencode) {
    return {
      variant: "contrast",
      label: probingSelected ? { key: "wsl.onboarding.distroStatus.checking" } : { key: "wsl.server.add" },
      disabled: true,
      action: null,
      loading: probingSelected,
      width: null
    };
  }
  if (!addServerOpencodeReady(input.opencodeCheck)) {
    const update = !!input.opencodeCheck?.resolvedPath && input.opencodeCheck.matchesDesktop === false;
    return {
      variant: "neutral",
      label: installingOpencode ? { key: "wsl.onboarding.updatingOpencode" } : update ? { key: "wsl.onboarding.updateOpencode" } : { key: "wsl.onboarding.installOpencode" },
      disabled: !!input.state?.job || input.adding,
      action: "install-opencode",
      loading: installingOpencode,
      width: update ? "138px" : "129px"
    };
  }
  return {
    variant: "contrast",
    label: input.adding ? { key: "wsl.onboarding.adding" } : { key: "wsl.server.add" },
    disabled: input.adding || !!input.state?.job,
    action: "add",
    loading: input.adding,
    width: null
  };
}
function addServerOpencodeReady(check) {
  return !!check?.resolvedPath && check.matchesDesktop !== false && !check.error;
}
function addServerSelectedDistroSettled(state, selectedDistro) {
  if (!selectedDistro) return false;
  const installed = state?.installed.find((item) => item.name === selectedDistro);
  if (installed?.version === 1) return false;
  if (!state?.distroProbes[selectedDistro]) return false;
  if (!wslDistroReady(state, selectedDistro)) return true;
  return !!state.opencodeChecks[selectedDistro];
}
function addServerInstallableDistros(installedDistros, onlineDistros) {
  const installed = new Set(installedDistros.map((item) => item.name));
  const hasVersionedUbuntu = onlineDistros.some((item) => /^Ubuntu-\d/.test(item.name));
  return onlineDistros.filter((item) => !installed.has(item.name)).filter((item) => item.name !== "Ubuntu" || !hasVersionedUbuntu);
}
function addServerFilteredInstallableDistros(installableDistros, search) {
  const query = search.trim();
  if (!query) return installableDistros;
  return fuzzysort.go(query, installableDistros, { keys: ["label", "name"] }).map((item) => item.obj);
}
function addServerCatalogTarget(target, distros) {
  if (target && distros.some((item) => item.name === target)) return target;
  return distros[0]?.name ?? null;
}
function addableProbePlan(input) {
  const state = input.state;
  if (!state?.runtime?.available || state.pendingRestart || input.view !== "main" || input.adding) return;
  if (state.job) return;
  const ordered = input.selectedDistro ? [
    ...input.addableInstalledDistros.filter((item) => item.name === input.selectedDistro),
    ...input.addableInstalledDistros.filter((item) => item.name !== input.selectedDistro)
  ] : input.addableInstalledDistros;
  const pending = ordered.flatMap((item) => {
    if (item.version === 1) return [];
    if (!state.distroProbes[item.name]) return [`distro:${item.name}`];
    if (wslDistroReady(state, item.name) && !state.opencodeChecks[item.name]) return [`opencode:${item.name}`];
    return [];
  });
  if (!pending.length) return;
  return {
    key: pending.join("|"),
    distros: ordered.filter((item) => item.version !== 1).map((item) => item.name)
  };
}
function autoProbePlan(input) {
  if (!input.state || input.busy || input.state.pendingRestart) return;
  if (!input.state.runtime) return { key: "runtime", action: "probeRuntime" };
  if (!input.state.runtime.available) return;
  if (input.state.installed.length || input.state.online.length) return;
  return { key: "distros", action: "refreshDistros" };
}
function addServerProbePlan(input) {
  const auto = autoProbePlan({ state: input.state, busy: input.busy });
  if (auto) return { kind: "auto", key: `auto:${auto.key}`, plan: auto };
  const addable = addableProbePlan(input);
  if (addable) return { kind: "addable", key: `addable:${addable.key}`, plan: addable };
}
function createProbeFailureGate() {
  let failed;
  return {
    accepts(key) {
      return key !== failed;
    },
    settle(key, error) {
      if (error) failed = key;
    },
    reset() {
      failed = void 0;
    }
  };
}
async function runAddableProbePlan(input) {
  await input.api.probeAddable(input.plan.distros);
}
function useWslAddServerProbes(input) {
  const gate = createProbeFailureGate();
  const probe = useMutation(() => ({
    mutationFn: async (command) => {
      if (command.kind === "addable") {
        await runAddableProbePlan({ plan: command.plan, api: input.api });
        return;
      }
      if (command.plan.action === "probeRuntime") await input.api.probeRuntime();
      if (command.plan.action === "refreshDistros") await input.api.refreshDistros();
    },
    onError: input.onError,
    onSettled: (_result, error, command) => {
      if (command) gate.settle(command.key, error);
    }
  }));
  createEffect(() => {
    if (probe.isPending) return;
    const command = addServerProbePlan({
      state: input.state(),
      view: input.view(),
      adding: input.adding(),
      busy: input.busy(),
      selectedDistro: input.selectedDistro(),
      addableInstalledDistros: input.addableInstalledDistros()
    });
    if (!command || !gate.accepts(command.key)) return;
    probe.mutate(command);
  });
  return {
    probingAddable: () => probe.isPending && probe.variables?.kind === "addable",
    resetProbeFailure: () => gate.reset()
  };
}
var _tmpl$$3 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-section-header><span class=settings-v2-wsl-section-title>`), _tmpl$2$1 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-distro-list>`), _tmpl$3$1 = /* @__PURE__ */ template(`<button type=button class=settings-v2-wsl-catalog-card><span class=settings-v2-wsl-catalog-icon aria-hidden=true><svg width=16 height=16 viewBox="0 0 16 16"fill=none xmlns=http://www.w3.org/2000/svg><path d="M13.5564 10.4443V13.5554H4.22309C3.24087 13.5554 2.44531 13.5554 2.44531 13.5554V10.4443M11.112 5.99989L8.00087 9.111L4.88976 5.99989M8.00087 9.111L8.00087 2.44434"stroke=currentColor></path></svg></span><span class=settings-v2-wsl-catalog-copy><span class=settings-v2-wsl-catalog-title></span><span class=settings-v2-wsl-catalog-description></span></span><span class=settings-v2-wsl-catalog-chevron aria-hidden=true><svg width=16 height=16 viewBox="0 0 16 16"fill=none xmlns=http://www.w3.org/2000/svg><path d="M6 12L10 8L6 4"stroke=currentColor>`), _tmpl$4$1 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-loading>`), _tmpl$5$1 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-catalog-list>`), _tmpl$6$1 = /* @__PURE__ */ template(`<span class=settings-v2-wsl-distro-label>`), _tmpl$7 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-distro-list><div class=settings-v2-wsl-distro-empty>`), _tmpl$8 = /* @__PURE__ */ template(`<span class=settings-v2-wsl-distro-status>`), _tmpl$9 = /* @__PURE__ */ template(`<p class=settings-v2-wsl-unavailable-error>`), _tmpl$0 = /* @__PURE__ */ template(`<div class=settings-v2-wsl-not-installed-content><div class=settings-v2-wsl-not-installed-message><svg class=settings-v2-wsl-not-installed-icon width=24 height=24 viewBox="0 0 24 24"fill=none xmlns=http://www.w3.org/2000/svg aria-hidden=true><g clip-path=url(#settings-v2-wsl-warning-clip)><path fill-rule=evenodd clip-rule=evenodd d="M12 -0.00244141L23.6926 20.2498H0.308594L12 -0.00244141ZM12.7954 6.32932C12.5844 6.11834 12.2982 5.99982 11.9999 5.99982C11.7015 5.99982 11.4154 6.11834 11.2044 6.32932C10.9934 6.5403 10.8749 6.82645 10.8749 7.12482V11.6248C10.8749 11.9232 10.9934 12.2093 11.2044 12.4203C11.4154 12.6313 11.7015 12.7498 11.9999 12.7498C12.2982 12.7498 12.5844 12.6313 12.7954 12.4203C13.0064 12.2093 13.1249 11.9232 13.1249 11.6248V7.12482C13.1249 6.82645 13.0064 6.5403 12.7954 6.32932ZM13.0605 17.5605C12.7792 17.8418 12.3977 17.9998 11.9999 17.9998C11.6021 17.9998 11.2205 17.8418 10.9392 17.5605C10.6579 17.2792 10.4999 16.8976 10.4999 16.4998C10.4999 16.102 10.6579 15.7205 10.9392 15.4392C11.2205 15.1579 11.6021 14.9998 11.9999 14.9998C12.3977 14.9998 12.7792 15.1579 13.0605 15.4392C13.3418 15.7205 13.4999 16.102 13.4999 16.4998C13.4999 16.8976 13.3418 17.2792 13.0605 17.5605Z"fill=#DBDBDB></path></g><defs><clipPath id=settings-v2-wsl-warning-clip><rect width=24 height=24 fill=white></rect></clipPath></defs></svg><h2 class=settings-v2-wsl-not-installed-title></h2><p class=settings-v2-wsl-not-installed-description>`);
function isWslRuntimeMissing(error) {
  if (!error) return true;
  return /WSL is not installed|not been installed|wsl(?:\.exe)? --install/i.test(error);
}
function translate(language, value) {
  if (value.params) return language.t(value.key, value.params);
  return language.t(value.key);
}
function DialogAddWslServer(props = {}) {
  const language = useLanguage();
  const controller = useWslAddServerController(props);
  const model = controller.model;
  const primaryButton = () => model().primaryButton;
  const primaryButtonStyle = () => {
    const width = primaryButton().width;
    if (!width) return void 0;
    return {
      width
    };
  };
  return createComponent(Show, {
    get when() {
      return memo(() => !!!controller.wslServers.isPending)() && !controller.wslServers.isError;
    },
    get fallback() {
      return createComponent(Dialog, {
        fit: true,
        "class": "settings-v2-wsl-dialog",
        get children() {
          return createComponent(Show, {
            get when() {
              return !controller.wslServers.isError;
            },
            get fallback() {
              return (() => {
                var _el$0 = _tmpl$4$1();
                insert(_el$0, () => controller.loadError());
                return _el$0;
              })();
            },
            get children() {
              var _el$9 = _tmpl$4$1();
              insert(_el$9, createComponent(LoaderV2, {}));
              return _el$9;
            }
          });
        }
      });
    },
    get children() {
      return createComponent(Show, {
        get when() {
          return model().runtimeState === "ready";
        },
        get fallback() {
          return createComponent(Show, {
            get when() {
              return model().runtimeState === "checking" || model().runtimeState === "loading";
            },
            get fallback() {
              return createComponent(DialogWslSetup, {
                get state() {
                  return model().runtimeState;
                },
                get error() {
                  return controller.runtimeError();
                },
                get installable() {
                  return isWslRuntimeMissing(controller.runtimeError());
                },
                get busy() {
                  return model().busy;
                },
                get onInstall() {
                  return controller.installWsl;
                }
              });
            },
            get children() {
              return createComponent(Dialog, {
                fit: true,
                "class": "settings-v2-wsl-dialog",
                get children() {
                  var _el$1 = _tmpl$4$1();
                  insert(_el$1, createComponent(LoaderV2, {}));
                  return _el$1;
                }
              });
            }
          });
        },
        get children() {
          return createComponent(Dialog, {
            fit: true,
            "class": "settings-v2-wsl-dialog",
            get children() {
              return [createComponent(DialogHeader, {
                hideClose: true,
                get children() {
                  return createComponent(DialogTitle, {
                    get children() {
                      return memo(() => controller.view() === "main")() ? language.t("wsl.server.add") : language.t("wsl.onboarding.installDistro");
                    }
                  });
                }
              }), createComponent(DividerV2, {}), createComponent(Show, {
                get when() {
                  return controller.view() === "main";
                },
                get fallback() {
                  return [createComponent(DialogBody, {
                    "class": "settings-v2-wsl-dialog-body settings-v2-wsl-catalog-picker",
                    get children() {
                      return [createComponent(TextInputV2, {
                        "class": "settings-v2-wsl-catalog-search",
                        appearance: "large",
                        get placeholder() {
                          return language.t("wsl.onboarding.searchDistros");
                        },
                        get value() {
                          return controller.catalogSearch();
                        },
                        get disabled() {
                          return model().busy;
                        },
                        onInput: (event) => controller.setCatalogSearch(event.currentTarget.value)
                      }), (() => {
                        var _el$10 = _tmpl$5$1();
                        insert(_el$10, createComponent(RadioGroupV2, {
                          hideLabel: true,
                          "class": "settings-v2-wsl-distro-group",
                          get label() {
                            return language.t("wsl.onboarding.installDistro");
                          },
                          get value() {
                            return model().catalogTarget ?? void 0;
                          },
                          get onChange() {
                            return controller.setCatalogTarget;
                          },
                          get disabled() {
                            return model().busy;
                          },
                          get children() {
                            return createComponent(For, {
                              get each() {
                                return model().filteredInstallableDistros;
                              },
                              children: (item) => createComponent(RadioItemV2, {
                                "class": "settings-v2-wsl-distro-row settings-v2-wsl-catalog-row",
                                get value() {
                                  return item.name;
                                },
                                get disabled() {
                                  return model().busy;
                                },
                                get label() {
                                  return (() => {
                                    var _el$11 = _tmpl$6$1();
                                    insert(_el$11, () => item.label);
                                    return _el$11;
                                  })();
                                }
                              })
                            });
                          }
                        }));
                        return _el$10;
                      })()];
                    }
                  }), createComponent(DialogFooter, {
                    get children() {
                      return [createComponent(ButtonV2, {
                        variant: "neutral",
                        get disabled() {
                          return model().busy;
                        },
                        get onClick() {
                          return controller.closeCatalog;
                        },
                        get children() {
                          return language.t("common.cancel");
                        }
                      }), createComponent(ButtonV2, {
                        get variant() {
                          return model().installingCatalogDistro ? "loading" : "contrast";
                        },
                        get disabled() {
                          return memo(() => !!!model().installingCatalogDistro)() && (model().busy || !model().catalogTarget);
                        },
                        style: {
                          width: "99px"
                        },
                        get onClick() {
                          return controller.installCatalogDistro;
                        },
                        get children() {
                          return createComponent(Show, {
                            get when() {
                              return model().installingCatalogDistro;
                            },
                            get fallback() {
                              return language.t("wsl.onboarding.installDistro");
                            },
                            get children() {
                              return createComponent(LoaderV2, {});
                            }
                          });
                        }
                      })];
                    }
                  })];
                },
                get children() {
                  return [createComponent(DialogBody, {
                    "class": "settings-v2-wsl-dialog-body",
                    get children() {
                      return [(() => {
                        var _el$ = _tmpl$$3(), _el$2 = _el$.firstChild;
                        insert(_el$2, () => language.t("wsl.onboarding.installedDistros"));
                        insert(_el$, createComponent(ButtonV2, {
                          variant: "ghost-muted",
                          size: "small",
                          get disabled() {
                            return model().busy;
                          },
                          get onClick() {
                            return controller.refreshDistros;
                          },
                          get children() {
                            return language.t("wsl.onboarding.checkAgain");
                          }
                        }), null);
                        return _el$;
                      })(), createComponent(Show, {
                        get when() {
                          return model().addableInstalledDistros.length > 0;
                        },
                        get fallback() {
                          return (() => {
                            var _el$12 = _tmpl$7(), _el$13 = _el$12.firstChild;
                            insert(_el$13, (() => {
                              var _c$ = memo(() => !!model().visibleInstalledDistros.length);
                              return () => _c$() ? language.t("wsl.onboarding.allDistrosAdded") : language.t("wsl.onboarding.noDistros");
                            })());
                            return _el$12;
                          })();
                        },
                        get children() {
                          var _el$3 = _tmpl$2$1();
                          insert(_el$3, createComponent(RadioGroupV2, {
                            hideLabel: true,
                            "class": "settings-v2-wsl-distro-group",
                            get label() {
                              return language.t("wsl.onboarding.installedDistros");
                            },
                            get value() {
                              return model().selectedDistro ?? void 0;
                            },
                            get onChange() {
                              return controller.setSelectedDistro;
                            },
                            get disabled() {
                              return model().busy;
                            },
                            get children() {
                              return createComponent(For, {
                                get each() {
                                  return model().addableInstalledDistros;
                                },
                                children: (item) => {
                                  const status = () => model().distroStatuses[item.name] ?? null;
                                  return createComponent(RadioItemV2, {
                                    get ["class"]() {
                                      return `settings-v2-wsl-distro-row${item.version === 1 ? " settings-v2-wsl-distro-row--unsupported" : ""}`;
                                    },
                                    get value() {
                                      return item.name;
                                    },
                                    get disabled() {
                                      return item.version === 1 || model().busy;
                                    },
                                    get label() {
                                      return (() => {
                                        var _el$14 = _tmpl$6$1();
                                        insert(_el$14, () => item.name);
                                        return _el$14;
                                      })();
                                    },
                                    get description() {
                                      return createComponent(Show, {
                                        get when() {
                                          return status();
                                        },
                                        children: (value) => (() => {
                                          var _el$15 = _tmpl$8();
                                          insert(_el$15, () => translate(language, value().label));
                                          createRenderEffect(() => setAttribute(_el$15, "data-tone", value().tone));
                                          return _el$15;
                                        })()
                                      });
                                    }
                                  });
                                }
                              });
                            }
                          }));
                          return _el$3;
                        }
                      }), createComponent(Show, {
                        get when() {
                          return model().installableDistros.length > 0;
                        },
                        get children() {
                          var _el$4 = _tmpl$3$1(), _el$5 = _el$4.firstChild, _el$6 = _el$5.nextSibling, _el$7 = _el$6.firstChild, _el$8 = _el$7.nextSibling;
                          addEventListener(_el$4, "click", controller.openCatalog, true);
                          insert(_el$7, () => language.t("wsl.onboarding.needAnotherDistro"));
                          insert(_el$8, () => language.t("wsl.onboarding.needAnotherDistroHint"));
                          createRenderEffect(() => _el$4.disabled = model().busy);
                          return _el$4;
                        }
                      })];
                    }
                  }), createComponent(DialogFooter, {
                    get children() {
                      return [createComponent(ButtonV2, {
                        variant: "neutral",
                        get disabled() {
                          return controller.adding();
                        },
                        get onClick() {
                          return controller.close;
                        },
                        get children() {
                          return language.t("common.cancel");
                        }
                      }), createComponent(ButtonV2, {
                        get variant() {
                          return memo(() => !!primaryButton().loading)() ? "loading" : primaryButton().variant;
                        },
                        get disabled() {
                          return memo(() => !!!primaryButton().loading)() && primaryButton().disabled;
                        },
                        get style() {
                          return primaryButtonStyle();
                        },
                        get onClick() {
                          return controller.runPrimary;
                        },
                        get children() {
                          return createComponent(Show, {
                            get when() {
                              return primaryButton().loading;
                            },
                            get fallback() {
                              return translate(language, primaryButton().label);
                            },
                            get children() {
                              return createComponent(LoaderV2, {});
                            }
                          });
                        }
                      })];
                    }
                  })];
                }
              })];
            }
          });
        }
      });
    }
  });
}
function useWslAddServerController(props) {
  const language = useLanguage();
  const platform = usePlatform();
  const dialog = useDialog();
  const wslServers = useWslServers();
  const api = platform.wslServers;
  const [store, setStore] = createStore({
    view: "main",
    selectedDistro: null,
    catalogSearch: "",
    catalogTarget: null,
    adding: false
  });
  const current = () => wslServers.data;
  const viewModel = (probingAddable) => addServerViewModel({
    state: current(),
    view: store.view,
    selectedDistro: store.selectedDistro,
    catalogSearch: store.catalogSearch,
    catalogTarget: store.catalogTarget,
    adding: store.adding,
    probingAddable
  });
  const baseModel = createMemo(() => viewModel(false));
  const probes = useWslAddServerProbes({
    state: current,
    api,
    view: () => store.view,
    adding: () => store.adding,
    busy: () => baseModel().busy,
    selectedDistro: () => baseModel().selectedDistro,
    addableInstalledDistros: () => baseModel().addableInstalledDistros,
    onError: (error) => requestError(language, error)
  });
  const model = createMemo(() => viewModel(probes.probingAddable()));
  const openCatalog = () => {
    const first = model().installableDistros[0];
    setStore({
      view: "catalog",
      catalogSearch: "",
      catalogTarget: first?.name ?? null
    });
  };
  const run = async (action) => {
    try {
      await action();
    } catch (err) {
      requestError(language, err);
    }
  };
  const refreshDistros = () => {
    void run(async () => {
      probes.resetProbeFailure();
      await api.refreshDistros();
    });
  };
  const installDistro = (name) => {
    void run(async () => {
      probes.resetProbeFailure();
      await api.installDistro(name);
      setStore("view", "main");
    });
  };
  const installCatalogDistro = () => {
    if (model().installingCatalogDistro) return;
    const name = model().catalogTarget;
    if (!name) return;
    installDistro(name);
  };
  const closeCatalog = () => {
    probes.resetProbeFailure();
    setStore({
      view: "main",
      catalogSearch: "",
      catalogTarget: null
    });
  };
  const runPrimary = async () => {
    const button = model().primaryButton;
    if (button.loading) return;
    const distro = model().selectedDistro;
    const action = button.action;
    if (!distro || !action) return;
    if (action === "install-opencode") {
      await run(() => api.installOpencode(distro));
      return;
    }
    setStore("adding", true);
    try {
      await api.addServer(distro);
      if (props.onAdded) {
        await props.onAdded(distro);
      } else {
        dialog.close();
      }
    } catch (err) {
      requestError(language, err);
    } finally {
      setStore("adding", false);
    }
  };
  const loadError = () => {
    const error = wslServers.error;
    if (!error) return language.t("wsl.onboarding.loadFailed");
    return error instanceof Error ? error.message : String(error);
  };
  return {
    wslServers,
    model,
    loadError,
    runtimeError: () => current()?.runtime?.error ?? null,
    view: () => store.view,
    catalogSearch: () => store.catalogSearch,
    adding: () => store.adding,
    setCatalogSearch: (value) => setStore("catalogSearch", value),
    setCatalogTarget: (value) => setStore("catalogTarget", value),
    setSelectedDistro: (value) => setStore("selectedDistro", value),
    openCatalog,
    closeCatalog,
    refreshDistros,
    installCatalogDistro,
    installWsl: () => void run(() => api.installWsl()),
    runPrimary: () => void runPrimary(),
    close: () => dialog.close()
  };
}
function DialogWslSetup(props) {
  const language = useLanguage();
  const dialog = useDialog();
  const title = () => props.state === "pendingRestart" ? language.t("wsl.onboarding.restartRequired") : props.installable ? language.t("wsl.onboarding.wslNotInstalled.title") : language.t("wsl.onboarding.wslUnavailable.title");
  const description = () => {
    if (props.state === "pendingRestart") return language.t("wsl.onboarding.windowsRestartRequired");
    if (!props.installable) return language.t("wsl.onboarding.wslUnavailable.description");
    return language.t("wsl.onboarding.wslNotInstalled.description");
  };
  return createComponent(Dialog, {
    fit: true,
    "class": "settings-v2-wsl-not-installed-dialog",
    get children() {
      var _el$16 = _tmpl$0(), _el$17 = _el$16.firstChild, _el$18 = _el$17.firstChild, _el$19 = _el$18.nextSibling, _el$20 = _el$19.nextSibling;
      insert(_el$19, title);
      insert(_el$20, description);
      insert(_el$17, createComponent(Show, {
        get when() {
          return memo(() => !!!props.installable)() && props.error;
        },
        get children() {
          var _el$21 = _tmpl$9();
          insert(_el$21, () => props.error);
          return _el$21;
        }
      }), null);
      insert(_el$16, createComponent(Show, {
        get when() {
          return memo(() => props.state === "unavailable")() && props.installable;
        },
        get children() {
          return createComponent(ButtonV2, {
            variant: "neutral",
            get disabled() {
              return props.busy;
            },
            get onClick() {
              return props.onInstall;
            },
            get children() {
              return language.t("wsl.onboarding.installWsl");
            }
          });
        }
      }), null);
      insert(_el$16, createComponent(Show, {
        get when() {
          return props.state !== "unavailable";
        },
        get children() {
          return createComponent(ButtonV2, {
            variant: "neutral",
            onClick: () => dialog.close(),
            get children() {
              return language.t("common.close");
            }
          });
        }
      }), null);
      return _el$16;
    }
  });
}
function requestError(language, err) {
  console.error("WSL servers request failed", err instanceof Error ? err.stack ?? err.message : String(err));
  showToast$1({
    variant: "error",
    title: language.t("common.requestFailed"),
    description: err instanceof Error ? err.message : String(err)
  });
}
delegateEvents(["click"]);
var _tmpl$$2 = /* @__PURE__ */ template(`<div class=settings-v2-servers-row><div class=settings-v2-servers-lead><div class=settings-v2-servers-copy><span class="flex min-w-0 items-center gap-1"><span class=settings-v2-servers-name></span><span class="shrink-0 rounded-[3px] border border-v2-border-border-base px-1 py-0.5 text-[9px] leading-none text-v2-text-text-muted"></span></span><span class=settings-v2-servers-meta></span></div></div><div class=settings-v2-servers-actions>`);
function isWslServer(server) {
  return server.type === "sidecar" && server.variant === "wsl";
}
function AddServerMenu(props) {
  const platform = usePlatform();
  const dialog = useDialog();
  const language = useLanguage();
  const openAddWsl = () => {
    dialog.push(() => createComponent(DialogAddWslServer, {}));
  };
  return createComponent(Show, {
    get when() {
      return platform.wslServers;
    },
    get fallback() {
      return createComponent(ButtonV2, {
        variant: "ghost-muted",
        icon: "plus",
        get onClick() {
          return props.onAddServer;
        },
        get children() {
          return language.t("dialog.server.add.button");
        }
      });
    },
    get children() {
      return createComponent(MenuV2, {
        gutter: 4,
        modal: false,
        placement: "bottom-end",
        get children() {
          return [createComponent(MenuV2.Trigger, {
            as: ButtonV2,
            variant: "ghost-muted",
            icon: "plus",
            get children() {
              return language.t("dialog.server.add.button");
            }
          }), createComponent(MenuV2.Portal, {
            get children() {
              return createComponent(MenuV2.Content, {
                get children() {
                  return [createComponent(MenuV2.Item, {
                    get onSelect() {
                      return props.onAddServer;
                    },
                    get children() {
                      return language.t("dialog.server.add.button");
                    }
                  }), createComponent(MenuV2.Item, {
                    onSelect: openAddWsl,
                    get children() {
                      return language.t("wsl.server.add");
                    }
                  })];
                }
              });
            }
          })];
        }
      });
    }
  });
}
function useFilteredWslServers(filter) {
  const wsl = useWslServers();
  return createMemo(() => {
    const servers = wsl.data?.servers ?? [];
    const query = filter().trim();
    if (!query) return servers;
    return fuzzysort.go(query, servers, {
      keys: [(item) => item.config.distro, (item) => item.config.id]
    }).map((x) => x.obj);
  });
}
function WslServerSettings(props) {
  const platform = usePlatform();
  const language = useLanguage();
  const wsl = useWslServers();
  const api = platform.wslServers;
  const request = useMutation(() => ({
    mutationFn: (action) => action(),
    onError: (error) => showToast({
      variant: "error",
      title: language.t("common.requestFailed"),
      description: error instanceof Error ? error.message : String(error)
    })
  }));
  const remove = (key) => {
    request.mutate(() => props.controller.handleRemove(key));
  };
  return createComponent(Show, {
    when: api,
    get children() {
      return createComponent(For, {
        get each() {
          return props.servers();
        },
        children: (item) => {
          const key = ServerConnection.Key.make(item.config.id);
          const check = () => wsl.data?.opencodeChecks[item.config.distro];
          const opencodeAction = () => wslOpencodeAction(check());
          const busy = () => wsl.data?.job?.kind === "install-opencode" && wsl.data.job.distro === item.config.distro;
          return (() => {
            var _el$ = _tmpl$$2(), _el$2 = _el$.firstChild, _el$3 = _el$2.firstChild, _el$4 = _el$3.firstChild, _el$5 = _el$4.firstChild, _el$6 = _el$5.nextSibling, _el$7 = _el$4.nextSibling, _el$8 = _el$2.nextSibling;
            insert(_el$2, createComponent(ServerHealthIndicator, {
              get health() {
                return props.controller.status()[key];
              }
            }), _el$3);
            insert(_el$5, () => item.config.distro);
            insert(_el$6, () => language.t("wsl.server.label"));
            insert(_el$7, createComponent(Show, {
              get when() {
                return check()?.version;
              },
              children: (version) => `v${version()}`
            }));
            insert(_el$8, createComponent(Show, {
              get when() {
                return memo(() => !!props.controller.canDefault())() && props.controller.defaultKey() === key;
              },
              get children() {
                return createComponent(Tag, {
                  get children() {
                    return language.t("dialog.server.status.default");
                  }
                });
              }
            }), null);
            insert(_el$8, createComponent(Show, {
              get when() {
                return opencodeAction();
              },
              children: (label) => createComponent(ButtonV2, {
                size: "small",
                get disabled() {
                  return busy() || request.isPending;
                },
                onClick: () => api && request.mutate(() => api.installOpencode(item.config.distro)),
                get children() {
                  return memo(() => !!busy())() ? language.t("wsl.server.updating") : language.t(label());
                }
              })
            }), null);
            insert(_el$8, createComponent(MenuV2, {
              gutter: 4,
              modal: false,
              placement: "bottom-end",
              get children() {
                return [createComponent(MenuV2.Trigger, {
                  as: IconButtonV2,
                  variant: "ghost-muted",
                  size: "small",
                  get icon() {
                    return createComponent(Icon, {
                      name: "outline-dots"
                    });
                  },
                  get ["aria-label"]() {
                    return language.t("common.moreOptions");
                  }
                }), createComponent(MenuV2.Portal, {
                  get children() {
                    return createComponent(MenuV2.Content, {
                      get children() {
                        return createComponent(MenuV2.Group, {
                          get children() {
                            return [createComponent(MenuV2.GroupLabel, {
                              get children() {
                                return language.t("wsl.server.menu.label");
                              }
                            }), createComponent(Show, {
                              get when() {
                                return wslRuntimeRetryable(item.runtime);
                              },
                              get children() {
                                return createComponent(MenuV2.Item, {
                                  onSelect: () => api && request.mutate(() => api.startServer(key)),
                                  get children() {
                                    return language.t("wsl.server.retryStart");
                                  }
                                });
                              }
                            }), createComponent(Show, {
                              get when() {
                                return memo(() => !!props.controller.canDefault())() && props.controller.defaultKey() !== key;
                              },
                              get children() {
                                return createComponent(MenuV2.Item, {
                                  onSelect: () => props.controller.setDefault(key),
                                  get children() {
                                    return language.t("dialog.server.menu.default");
                                  }
                                });
                              }
                            }), createComponent(Show, {
                              get when() {
                                return memo(() => !!props.controller.canDefault())() && props.controller.defaultKey() === key;
                              },
                              get children() {
                                return createComponent(MenuV2.Item, {
                                  onSelect: () => props.controller.setDefault(null),
                                  get children() {
                                    return language.t("dialog.server.menu.defaultRemove");
                                  }
                                });
                              }
                            }), createComponent(MenuV2.Separator, {}), createComponent(MenuV2.Item, {
                              onSelect: () => remove(key),
                              get children() {
                                return language.t("dialog.server.menu.delete");
                              }
                            })];
                          }
                        });
                      }
                    });
                  }
                })];
              }
            }), null);
            return _el$;
          })();
        }
      });
    }
  });
}
var _tmpl$$1 = /* @__PURE__ */ template(`<div class=settings-v2-tab-search>`), _tmpl$2 = /* @__PURE__ */ template(`<div class="settings-v2-tab-header settings-v2-servers-header"><div class=settings-v2-tab-header-row><h2 class=settings-v2-tab-title>`), _tmpl$3 = /* @__PURE__ */ template(`<div class="settings-v2-tab-body settings-v2-servers">`), _tmpl$4 = /* @__PURE__ */ template(`<span class=settings-v2-servers-status-filter>&quot;<!>&quot;`), _tmpl$5 = /* @__PURE__ */ template(`<div class=settings-v2-servers-status><span>`), _tmpl$6 = /* @__PURE__ */ template(`<div class=settings-v2-servers-row><div class=settings-v2-servers-lead><div class=settings-v2-servers-copy><span class=settings-v2-servers-name></span><span class=settings-v2-servers-meta></span></div></div><div class=settings-v2-servers-actions>`);
const SettingsServersV2 = () => {
  const dialog = useDialog();
  const language = useLanguage();
  const controller = useServerManagementController();
  const [store, setStore] = createStore({
    filter: ""
  });
  const wslServers = useFilteredWslServers(() => store.filter);
  const showSearch = createMemo(() => controller.sortedItems().filter((item) => !isWslServer(item)).length + wslServers().length > 1);
  const filtered = createMemo(() => {
    const items = controller.sortedItems().filter((item) => !isWslServer(item));
    const query = store.filter.trim();
    if (!query) return items;
    return fuzzysort.go(query, items, {
      keys: [(item) => serverName(item), (item) => item.http.url]
    }).map((result) => result.obj);
  });
  const openAdd = () => {
    dialog.push(() => createComponent(DialogServerV2, {
      mode: "add"
    }));
  };
  const openEdit = (server) => {
    dialog.push(() => createComponent(DialogServerV2, {
      mode: "edit",
      server
    }));
  };
  return [(() => {
    var _el$ = _tmpl$2(), _el$2 = _el$.firstChild, _el$3 = _el$2.firstChild;
    insert(_el$3, () => language.t("status.popover.tab.servers"));
    insert(_el$2, createComponent(AddServerMenu, {
      onAddServer: openAdd
    }), null);
    insert(_el$, createComponent(Show, {
      get when() {
        return showSearch();
      },
      get children() {
        var _el$4 = _tmpl$$1();
        insert(_el$4, createComponent(TextInputV2, {
          type: "search",
          appearance: "base",
          get value() {
            return store.filter;
          },
          onInput: (event) => setStore("filter", event.currentTarget.value),
          get placeholder() {
            return language.t("dialog.server.search.placeholder");
          },
          spellcheck: false,
          autocorrect: "off",
          autocomplete: "off",
          autocapitalize: "off",
          get ["aria-label"]() {
            return language.t("dialog.server.search.placeholder");
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
                return createComponent(Icon, {
                  name: "close",
                  size: "large",
                  "class": "text-v2-icon-icon-muted"
                });
              },
              onClick: () => setStore("filter", "")
            });
          }
        }), null);
        return _el$4;
      }
    }), null);
    createRenderEffect(() => _el$.classList.toggle("settings-v2-tab-header--stacked", !!showSearch()));
    return _el$;
  })(), (() => {
    var _el$5 = _tmpl$3();
    insert(_el$5, createComponent(Show, {
      get when() {
        return filtered().length > 0 || wslServers().length > 0;
      },
      get fallback() {
        return (() => {
          var _el$6 = _tmpl$5(), _el$7 = _el$6.firstChild;
          insert(_el$7, (() => {
            var _c$ = memo(() => !!store.filter);
            return () => _c$() ? language.t("palette.empty") : language.t("dialog.server.empty");
          })());
          insert(_el$6, createComponent(Show, {
            get when() {
              return store.filter;
            },
            get children() {
              var _el$8 = _tmpl$4(), _el$9 = _el$8.firstChild, _el$1 = _el$9.nextSibling;
              _el$1.nextSibling;
              insert(_el$8, () => store.filter, _el$1);
              return _el$8;
            }
          }), null);
          return _el$6;
        })();
      },
      get children() {
        return createComponent(SettingsListV2, {
          get children() {
            return [createComponent(WslServerSettings, {
              controller,
              servers: wslServers
            }), createComponent(For, {
              get each() {
                return filtered();
              },
              children: (item) => {
                const key = ServerConnection.key(item);
                const health = () => controller.status()[key];
                const isDefault = () => controller.defaultKey() === key;
                return (() => {
                  var _el$10 = _tmpl$6(), _el$11 = _el$10.firstChild, _el$12 = _el$11.firstChild, _el$13 = _el$12.firstChild, _el$14 = _el$13.nextSibling, _el$15 = _el$11.nextSibling;
                  insert(_el$11, createComponent(ServerHealthIndicator, {
                    get health() {
                      return health();
                    }
                  }), _el$12);
                  insert(_el$13, () => serverName(item));
                  insert(_el$14, createComponent(Show, {
                    get when() {
                      return health()?.version;
                    },
                    get children() {
                      return ["v", memo(() => health()?.version)];
                    }
                  }), null);
                  insert(_el$14, createComponent(Show, {
                    get when() {
                      return memo(() => !!health()?.version)() && item.type === "http";
                    },
                    children: " • "
                  }), null);
                  insert(_el$14, createComponent(Show, {
                    get when() {
                      return memo(() => item.type === "http")() && item.http.username;
                    },
                    get fallback() {
                      return createComponent(Show, {
                        get when() {
                          return item.type === "http";
                        },
                        get children() {
                          return language.t("server.row.noUsername");
                        }
                      });
                    },
                    get children() {
                      return item.http.username;
                    }
                  }), null);
                  insert(_el$15, createComponent(Show, {
                    get when() {
                      return memo(() => !!controller.canDefault())() && isDefault();
                    },
                    get children() {
                      return createComponent(Tag, {
                        get children() {
                          return language.t("dialog.server.status.default");
                        }
                      });
                    }
                  }), null);
                  insert(_el$15, createComponent(ServerRowMenu, {
                    server: item,
                    controller,
                    onEdit: openEdit
                  }), null);
                  return _el$10;
                })();
              }
            })];
          }
        });
      }
    }));
    return _el$5;
  })()];
};
var _tmpl$ = /* @__PURE__ */ template(`<div class="flex flex-col justify-between h-full w-full"><div class="flex flex-col gap-3 w-full"><div class="flex flex-col gap-3"><div class="flex flex-col gap-1.5"><div class="flex flex-col gap-1.5 w-full"></div></div><div class="flex flex-col gap-1.5"><div class="flex flex-col gap-1.5 w-full"></div></div></div></div><div class=settings-v2-nav-footer><span></span><span>v`);
const DialogSettings = (props) => {
  const language = useLanguage();
  const platform = usePlatform();
  const dialog = useDialog();
  const layout = useLayout();
  const tabs = useTabs();
  const serverSync = useServerSync();
  const [tab, setTab] = createSignal(props.defaultValue ?? "general");
  const directory = createMemo(() => {
    const route = layout.route();
    if (route.type === "dir-new-sesssion") return route.dir;
    if (route.type === "draft") {
      const draft = tabs.store.find((item) => item.type === "draft" && item.draftID === route.draftID);
      return draft?.type === "draft" ? draft.directory : void 0;
    }
    if (route.type === "session") return serverSync().session.get(route.sessionId)?.directory;
    return void 0;
  });
  const showProviders = () => {
    void dialog.show(() => createComponent(DialogSettings, {
      get sessionID() {
        return props.sessionID;
      },
      defaultValue: "providers"
    }));
  };
  return createComponent(Dialog, {
    size: "x-large",
    variant: "settings",
    "class": "settings-v2-dialog",
    get children() {
      return createComponent(TabsV2, {
        orientation: "vertical",
        variant: "settings",
        get value() {
          return tab();
        },
        onChange: (value) => void startTransition(() => setTab(value)),
        "class": "settings-v2",
        get children() {
          return [createComponent(TabsV2.List, {
            get children() {
              var _el$ = _tmpl$(), _el$2 = _el$.firstChild, _el$3 = _el$2.firstChild, _el$4 = _el$3.firstChild, _el$5 = _el$4.firstChild, _el$6 = _el$4.nextSibling, _el$7 = _el$6.firstChild, _el$8 = _el$2.nextSibling, _el$9 = _el$8.firstChild, _el$0 = _el$9.nextSibling;
              _el$0.firstChild;
              insert(_el$4, createComponent(TabsV2.SectionTitle, {
                get children() {
                  return language.t("settings.section.desktop");
                }
              }), _el$5);
              insert(_el$5, createComponent(TabsV2.Trigger, {
                value: "general",
                get children() {
                  return [createComponent(Icon$1, {
                    name: "sliders"
                  }), memo(() => language.t("settings.tab.general"))];
                }
              }), null);
              insert(_el$5, createComponent(TabsV2.Trigger, {
                value: "shortcuts",
                get children() {
                  return [createComponent(Icon$1, {
                    name: "keyboard"
                  }), memo(() => language.t("settings.tab.shortcuts"))];
                }
              }), null);
              insert(_el$6, createComponent(TabsV2.SectionTitle, {
                get children() {
                  return language.t("settings.section.server");
                }
              }), _el$7);
              insert(_el$7, createComponent(TabsV2.Trigger, {
                value: "servers",
                get children() {
                  return [createComponent(Icon$1, {
                    name: "server"
                  }), memo(() => language.t("status.popover.tab.servers"))];
                }
              }), null);
              insert(_el$7, createComponent(TabsV2.Trigger, {
                value: "providers",
                get children() {
                  return [createComponent(Icon$1, {
                    name: "providers"
                  }), memo(() => language.t("settings.providers.title"))];
                }
              }), null);
              insert(_el$7, createComponent(TabsV2.Trigger, {
                value: "models",
                get children() {
                  return [createComponent(Icon$1, {
                    name: "models"
                  }), memo(() => language.t("settings.models.title"))];
                }
              }), null);
              insert(_el$9, () => language.t("app.name.desktop"));
              insert(_el$0, () => platform.version, null);
              return _el$;
            }
          }), createComponent(TabsV2.Content, {
            value: "general",
            "class": "settings-v2-panel",
            get children() {
              return createComponent(SettingsGeneralV2, {
                get sessionID() {
                  return props.sessionID;
                }
              });
            }
          }), createComponent(TabsV2.Content, {
            value: "shortcuts",
            "class": "settings-v2-panel",
            get children() {
              return createComponent(SettingsKeybinds, {
                v2: true
              });
            }
          }), createComponent(TabsV2.Content, {
            value: "servers",
            "class": "settings-v2-panel",
            get children() {
              return createComponent(SettingsServersV2, {});
            }
          }), createComponent(TabsV2.Content, {
            value: "providers",
            "class": "settings-v2-panel",
            get children() {
              return createComponent(SettingsProvidersV2, {
                directory,
                onBack: showProviders
              });
            }
          }), createComponent(TabsV2.Content, {
            value: "models",
            "class": "settings-v2-panel",
            get children() {
              return createComponent(SettingsModelsV2, {});
            }
          })];
        }
      });
    }
  });
};
export {
  DialogSettings
};
//# sourceMappingURL=index-Bn0VJlx3.js.map
