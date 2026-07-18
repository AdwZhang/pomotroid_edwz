<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
  import Titlebar from '$lib/components/Titlebar.svelte';
  import Timer from '$lib/components/Timer.svelte';
  import MiniView from '$lib/components/MiniView.svelte';
  import { getSettings, getThemes, onSettingsChanged, onThemesChanged } from '$lib/ipc';
  import {
    getTimerState,
    onTimerTick,
    onTimerPaused,
    onTimerResumed,
    onRoundChange,
    onTimerReset,
    notificationShow,
  } from '$lib/ipc';
  import { settings } from '$lib/stores/settings';
  import { timerState } from '$lib/stores/timer';
  import { applyTheme } from '$lib/stores/theme';
  import { resolveThemeName } from '$lib/utils/theme';
  import { isMac } from '$lib/utils/platform';
  import { setLocale } from '$lib/locale.svelte.js';
  import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow';
  import { PhysicalSize } from '@tauri-apps/api/dpi';
  import type { UnlistenFn } from '@tauri-apps/api/event';
  import { info, error as logError } from '@tauri-apps/plugin-log';
  import { createLocalShortcutHandler } from '$lib/utils/localShortcuts';
  import * as m from '$paraglide/messages.js';

  // Local shortcut state — volume and fullscreen tracked separately so the
  // handler can read current values without waiting for settings:changed round-trip.
  let localVolume = $state(1.0);
  let preMuteVolume = $state(0.5);
  let isFullscreen = $state(false);

  // Mini 模式状态
  let isMiniMode = $state(false);

  // Mini 模式窗口尺寸
  const MINI_W = 260;
  const MINI_H = 56;

  // Base window dimensions (natural/default size).
  const BASE_W = 360;
  const BASE_H = 478;
  const TITLEBAR_H = 40;

  // Compact mode: when either dimension drops below this threshold,
  // hide non-essential elements (footer, label, play/pause) to show
  // only the timer dial — like an Apple Watch face.
  const COMPACT_THRESHOLD = 300;

  let uiScale = $state(1.0);
  let isCompact = $state(false);

  // Extra bottom padding added to <main> in compact mode.  Shifts the
  // dial upward so the whitespace sits at the bottom rather than being
  // split equally — compensates for the visual weight of the titlebar.
  const COMPACT_BOTTOM_PAD = 48;

  // 切换到 mini 模式
  async function switchToMini() {
    const win = getCurrentWebviewWindow();
    await win.setAlwaysOnTop(true);
    await win.setResizable(false);
    await win.setSize(new PhysicalSize(MINI_W, MINI_H));
    isMiniMode = true;
  }

  // 切换回标准模式
  async function switchToStandard() {
    const win = getCurrentWebviewWindow();
    await win.setAlwaysOnTop(false);
    await win.setResizable(true);
    await win.setSize(new PhysicalSize(BASE_W, BASE_H));
    isMiniMode = false;
  }

  $effect(() => {
    function update() {
      // Mini 模式下跳过 compact 缩放逻辑
      if (isMiniMode) return;
      const w = window.innerWidth;
      const h = window.innerHeight;
      isCompact = w < COMPACT_THRESHOLD || h < COMPACT_THRESHOLD;
      if (isCompact) {
        // Scale so the dial fills the available space, reserving
        // COMPACT_BOTTOM_PAD px for the intentional bottom whitespace.
        const available = Math.min(w - 16, h - TITLEBAR_H - 16 - COMPACT_BOTTOM_PAD);
        uiScale = Math.max(0.4, Math.min(available / 220, 4));
      } else {
        // Scale proportionally to the base window dimensions.
        uiScale = Math.max(0.5, Math.min(w / BASE_W, (h - TITLEBAR_H) / (BASE_H - TITLEBAR_H), 4));
      }
    }
    update();
    window.addEventListener('resize', update);
    return () => window.removeEventListener('resize', update);
  });

  async function startResize(direction: string) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await getCurrentWebviewWindow().startResizeDragging(direction as any);
  }

  onMount(() => {
    const cleanups: UnlistenFn[] = [];

    // Mount local keyboard shortcut handler.
    const shortcutHandler = createLocalShortcutHandler({
      getSettings: () => $settings,
      getVolume: () => localVolume,
      setVolume: (v) => {
        localVolume = v;
      },
      getPreMuteVolume: () => preMuteVolume,
      setPreMuteVolume: (v) => {
        preMuteVolume = v;
      },
      getFullscreen: () => isFullscreen,
      setFullscreen: (v) => {
        isFullscreen = v;
      },
    });
    document.addEventListener('keydown', shortcutHandler);
    cleanups.push(() => document.removeEventListener('keydown', shortcutHandler));

    (async () => {
      try {
        // Load settings from backend.
        const s = await getSettings();
        settings.set(s);
        localVolume = s.volume;

        // Apply the stored locale on mount.
        setLocale(s.language);
        await info(`[main] settings loaded, locale=${s.language}`);

        // Load and apply the active theme using OS color scheme.
        const themes = await getThemes();
        const osDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        const active = themes.find((t) => t.name === resolveThemeName(s, osDark)) ?? themes[0];
        if (active) applyTheme(active);
        await getCurrentWebviewWindow().show();
        await info(`[main] initialized, theme=${active?.name ?? 'none'}`);

        // 初始化计时器状态并注册事件监听（始终存在，不随 mini/标准模式切换而卸载）
        const initialTimer = await getTimerState();
        timerState.set(initialTimer);

        cleanups.push(
          await onTimerTick(({ elapsed_secs, total_secs }) => {
            timerState.update((s) => ({
              ...s,
              elapsed_secs,
              total_secs,
              is_running: true,
              is_paused: false,
            }));
          }),
          await onTimerPaused(({ elapsed_secs }) => {
            timerState.update((s) => ({
              ...s,
              elapsed_secs,
              is_running: false,
              is_paused: true,
            }));
          }),
          await onTimerResumed(({ elapsed_secs }) => {
            timerState.update((s) => ({
              ...s,
              elapsed_secs,
              is_running: true,
              is_paused: false,
            }));
          }),
          await onRoundChange((snap) => {
            timerState.set(snap);
            if ($settings.notifications_enabled) {
              let title: string;
              let body: string;
              if (snap.round_type === 'work') {
                const afterBreak =
                  snap.previous_round_type === 'short-break' ||
                  snap.previous_round_type === 'long-break';
                title = afterBreak ? m.notification_work_title() : m.notification_work_start_title();
                body = afterBreak ? m.notification_work_body() : m.notification_work_start_body();
              } else if (snap.round_type === 'short-break') {
                title = m.notification_short_break_title();
                body = m.notification_short_break_body();
              } else {
                title = m.notification_long_break_title();
                body = m.notification_long_break_body();
              }
              notificationShow(title, body).catch(() => {});
            }
          }),
          await onTimerReset((snap) => {
            timerState.set(snap);
          })
        );      } catch (e) {
        await logError(`[main] initialization failed: ${e}`);
        throw e;
      }

      // Live OS color scheme changes — re-resolve only in auto mode.
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      const mqListener = async (e: MediaQueryListEvent) => {
        if ($settings.theme_mode !== 'auto') return;
        const allThemes = await getThemes();
        const t = allThemes.find((th) => th.name === resolveThemeName($settings, e.matches));
        if (t) applyTheme(t);
      };
      mq.addEventListener('change', mqListener);
      cleanups.push(() => mq.removeEventListener('change', mqListener));

      // Keep settings store in sync with backend changes.
      cleanups.push(
        await onSettingsChanged(async (updated) => {
          const prevMode = $settings.theme_mode;
          const prevLight = $settings.theme_light;
          const prevDark = $settings.theme_dark;
          const prevLanguage = $settings.language;
          settings.set(updated);
          localVolume = updated.volume;
          if (updated.language !== prevLanguage) {
            setLocale(updated.language);
          }
          if (
            updated.theme_mode !== prevMode ||
            updated.theme_light !== prevLight ||
            updated.theme_dark !== prevDark
          ) {
            const allThemes = await getThemes();
            const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const t = allThemes.find((th) => th.name === resolveThemeName(updated, dark));
            if (t) applyTheme(t);
          }
        }),
        // Re-apply theme when custom themes are hot-reloaded.
        await onThemesChanged((updated) => {
          const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
          const current =
            updated.find((t) => t.name === resolveThemeName($settings, dark)) ?? updated[0];
          if (current) applyTheme(current);
        })
      );
    })();

    return () => {
      for (const fn of cleanups) fn();
    };
  });
</script>

{#if isMiniMode}
  <!-- Mini 模式：胶囊浮动条 -->
  <div class="app mini">
    <MiniView onSwitchToStandard={switchToStandard} />
  </div>
{:else}
  <!-- 标准模式 -->
  <!-- Resize handles — invisible edge/corner strips for decorations-free windows.
       Not needed on macOS where native resizing is provided by decorations:true. -->
  {#if !isMac}
    <!-- N -->
    <div class="rh rh-n" onmousedown={() => startResize('North')} role="none"></div>
    <!-- S -->
    <div class="rh rh-s" onmousedown={() => startResize('South')} role="none"></div>
    <!-- E -->
    <div class="rh rh-e" onmousedown={() => startResize('East')} role="none"></div>
    <!-- W -->
    <div class="rh rh-w" onmousedown={() => startResize('West')} role="none"></div>
    <!-- NE -->
    <div class="rh rh-ne" onmousedown={() => startResize('NorthEast')} role="none"></div>
    <!-- NW -->
    <div class="rh rh-nw" onmousedown={() => startResize('NorthWest')} role="none"></div>
    <!-- SE -->
    <div class="rh rh-se" onmousedown={() => startResize('SouthEast')} role="none"></div>
    <!-- SW -->
    <div class="rh rh-sw" onmousedown={() => startResize('SouthWest')} role="none"></div>
  {/if}

  <div class="app">
    <Titlebar onSwitchToMini={switchToMini} />
    <main class:compact={isCompact}>
      <Timer {isCompact} {uiScale} />
    </main>
  </div>
{/if}

<style>
  .app {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    animation: app-fade-in 0.4s var(--transition-slow) both;
  }

  .app.mini {
    border-radius: 12px;
    background: var(--color-background);
  }

  main {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }

  main.compact {
    /* Bottom padding provides breathing room below the mini controls. */
    padding-bottom: 8px;
  }

  /* ---------------------------------------------------------------------------
     Resize handles — positioned outside/over the window edges so the user can
     grab them to resize a decoration-free window (needed on Linux/Wayland and
     GNOME with undecorated windows).
     --------------------------------------------------------------------------- */
  :global(.rh) {
    position: fixed;
    z-index: 9999;
  }

  /* Edge handles */
  :global(.rh-n) {
    top: 0;
    left: 6px;
    right: 6px;
    height: 5px;
    cursor: n-resize;
  }
  :global(.rh-s) {
    bottom: 0;
    left: 6px;
    right: 6px;
    height: 5px;
    cursor: s-resize;
  }
  :global(.rh-e) {
    right: 0;
    top: 6px;
    bottom: 6px;
    width: 5px;
    cursor: e-resize;
  }
  :global(.rh-w) {
    left: 0;
    top: 6px;
    bottom: 6px;
    width: 5px;
    cursor: w-resize;
  }

  /* Corner handles (larger for easier grabbing) */
  :global(.rh-ne) {
    top: 0;
    right: 0;
    width: 10px;
    height: 10px;
    cursor: ne-resize;
  }
  :global(.rh-nw) {
    top: 0;
    left: 0;
    width: 10px;
    height: 10px;
    cursor: nw-resize;
  }
  :global(.rh-se) {
    bottom: 0;
    right: 0;
    width: 10px;
    height: 10px;
    cursor: se-resize;
  }
  :global(.rh-sw) {
    bottom: 0;
    left: 0;
    width: 10px;
    height: 10px;
    cursor: sw-resize;
  }
</style>
