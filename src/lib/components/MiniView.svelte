<script lang="ts">
  // Mini 模式胶囊浮动条 — 包含进度环、轮次标签、任务文本（跑马灯）、
  // 暂停时重置按钮、倒计时、以及悬浮时显示的切换/关闭按钮。
  import { onMount } from 'svelte';
  import { getCurrentWebviewWindow } from '@tauri-apps/api/webviewWindow';
  import { timerToggle, timerRestartRound } from '$lib/ipc';
  import { timerState } from '$lib/stores/timer';
  import { settings } from '$lib/stores/settings';
  import { setSetting } from '$lib/ipc';
  import MiniProgressRing from './MiniProgressRing.svelte';
  import * as m from '$paraglide/messages.js';

  interface Props {
    /** 切换回标准模式回调 */
    onSwitchToStandard: () => void;
  }

  let { onSwitchToStandard }: Props = $props();

  let snap = $derived($timerState);

  // 进度计算
  let progress = $derived(snap.total_secs > 0 ? snap.elapsed_secs / snap.total_secs : 0);

  // 剩余时间格式化
  let remainingSecs = $derived(Math.max(0, snap.total_secs - snap.elapsed_secs));
  let timeDisplay = $derived(() => {
    const mins = Math.floor(remainingSecs / 60);
    const secs = remainingSecs % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  });

  // 进度环颜色（跟主题色走）
  function roundColor(rt: string): string {
    if (rt === 'work') return 'var(--color-focus-round)';
    if (rt === 'short-break') return 'var(--color-short-round)';
    return 'var(--color-long-round)';
  }

  // 轮次标签
  function roundLabel(rt: string): string {
    if (rt === 'work') return m.round_label_work();
    if (rt === 'short-break') return m.round_label_short_break();
    return m.round_label_long_break();
  }

  // 悬浮控件 — 鼠标悬浮 >500ms 后显示
  let hoverVisible = $state(false);
  let hoverTimer: ReturnType<typeof setTimeout> | null = null;

  function onMouseEnter() {
    hoverTimer = setTimeout(() => {
      hoverVisible = true;
    }, 500);
  }

  function onMouseLeave() {
    if (hoverTimer) {
      clearTimeout(hoverTimer);
      hoverTimer = null;
    }
    // 延迟 300ms 隐藏
    setTimeout(() => {
      hoverVisible = false;
    }, 300);
  }

  // 任务文本编辑
  let isEditingNote = $state(false);
  let localNoteValue = $state($settings.current_task_note);
  let noteInputEl: HTMLInputElement | undefined = $state();
  let debounceTimer: ReturnType<typeof setTimeout> | null = null;

  // 同步外部设置变更
  $effect(() => {
    localNoteValue = $settings.current_task_note;
  });

  function enterEditNote() {
    isEditingNote = true;
    requestAnimationFrame(() => noteInputEl?.focus());
  }

  function exitEditNote() {
    isEditingNote = false;
  }

  function handleNoteInput(e: Event) {
    const target = e.target as HTMLInputElement;
    localNoteValue = target.value;
    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(async () => {
      const updated = await setSetting('current_task_note', localNoteValue);
      settings.set(updated);
    }, 300);
  }

  // 跑马灯：检测文本是否溢出
  let marqueeContainer: HTMLElement | undefined = $state();
  let marqueeText: HTMLElement | undefined = $state();
  let needsMarquee = $state(false);

  $effect(() => {
    // 依赖 localNoteValue 触发重新检测
    void localNoteValue;
    requestAnimationFrame(() => {
      if (marqueeContainer && marqueeText) {
        needsMarquee = marqueeText.scrollWidth > marqueeContainer.clientWidth;
      }
    });
  });

  // 关闭窗口
  async function closeWindow() {
    await getCurrentWebviewWindow().close();
  }

  // 是否显示任务文本区域
  let showTaskNote = $derived($settings.task_notes_enabled && snap.round_type === 'work');

  onMount(() => {
    return () => {
      if (hoverTimer) clearTimeout(hoverTimer);
      if (debounceTimer) clearTimeout(debounceTimer);
    };
  });
</script>

<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="mini-view"
  data-tauri-drag-region
  onmouseenter={onMouseEnter}
  onmouseleave={onMouseLeave}
>
  <!-- 上行：轮次标签 -->
  <div class="top-row" data-tauri-drag-region>
    <span
      class="round-label"
      style="color: {roundColor(snap.round_type)}"
      data-tauri-drag-region
    >
      {roundLabel(snap.round_type)}
    </span>
  </div>

  <!-- 下行：进度环 + 任务文本 + 重置按钮 + 时间 -->
  <div class="bottom-row" data-tauri-drag-region>
    <MiniProgressRing
      {progress}
      color={roundColor(snap.round_type)}
      isRunning={snap.is_running}
      onToggle={timerToggle}
    />

    <!-- 任务文本区域 -->
    {#if showTaskNote}
      {#if isEditingNote}
        <!-- 编辑模式 -->
        <div class="note-edit">
          <input
            bind:this={noteInputEl}
            type="text"
            maxlength={100}
            value={localNoteValue}
            oninput={handleNoteInput}
            onblur={exitEditNote}
            onkeydown={(e) => {
              if (e.key === 'Enter' || e.key === 'Escape') {
                (e.target as HTMLInputElement).blur();
              }
            }}
            placeholder={m.task_note_placeholder()}
            class="note-input"
          />
        </div>
      {:else}
        <!-- 显示模式（跑马灯） -->
        <div class="note-display" data-tauri-drag-region>
          <div class="marquee-container" bind:this={marqueeContainer}>
            <span
              class="marquee-text"
              class:animate={needsMarquee}
              bind:this={marqueeText}
            >
              {localNoteValue || ''}
            </span>
          </div>
          <button class="edit-btn" onclick={enterEditNote} aria-label="Edit task note">
            <svg width="10" height="10" viewBox="0 0 16 16" fill="currentColor">
              <path d="M12.146.854a.5.5 0 0 1 .708 0l2.292 2.292a.5.5 0 0 1 0 .708L5.707 13.293a.5.5 0 0 1-.198.13l-3.5 1.25a.5.5 0 0 1-.632-.632l1.25-3.5a.5.5 0 0 1 .13-.198L12.146.854zM13 2.207 11.293 3.914l.793.793L13.793 3 13 2.207zM4.06 11.647l-.884 2.476 2.476-.884L11.44 7.45l-1.59-1.59L4.06 11.647z"/>
            </svg>
          </button>
        </div>
      {/if}
    {:else}
      <!-- 无任务文本时占位 -->
      <div class="spacer" data-tauri-drag-region></div>
    {/if}

    <!-- 暂停时显示重置按钮 -->
    {#if snap.is_paused}
      <button class="reset-btn" onclick={timerRestartRound} aria-label="Reset round">
        <svg width="10" height="10" viewBox="0 0 16 16">
          <rect x="2" y="2" width="12" height="12" rx="1.5" fill="currentColor" />
        </svg>
      </button>
    {/if}

    <!-- 倒计时时间 -->
    <span class="time-display" data-tauri-drag-region>{timeDisplay()}</span>
  </div>

  <!-- 悬浮控件 — 右上角 -->
  {#if hoverVisible}
    <div class="hover-controls">
      <button class="hover-btn" onclick={onSwitchToStandard} aria-label="Switch to standard mode">
        <!-- 展开/标准模式图标 -->
        <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
          <rect x="1" y="1" width="14" height="14" rx="2" stroke="currentColor" stroke-width="1.5" />
          <line x1="8" y1="4" x2="8" y2="12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
          <line x1="4" y1="8" x2="12" y2="8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
        </svg>
      </button>
      <button class="hover-btn close" onclick={closeWindow} aria-label="Close">
        <svg width="10" height="10" viewBox="0 0 12 12">
          <line x1="1" y1="1" x2="11" y2="11" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
          <line x1="11" y1="1" x2="1" y2="11" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
        </svg>
      </button>
    </div>
  {/if}
</div>

<style>
  .mini-view {
    width: 100%;
    height: 56px;
    display: flex;
    flex-direction: column;
    padding: 4px 12px 6px;
    box-sizing: border-box;
    position: relative;
    overflow: hidden;
    user-select: none;
  }

  /* 上行：轮次标签 */
  .top-row {
    display: flex;
    align-items: center;
    padding-left: 36px; /* 与进度环下方文本对齐 */
    height: 16px;
  }

  .round-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  /* 下行 */
  .bottom-row {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: 1;
    min-width: 0;
  }

  /* 任务文本显示区 */
  .note-display {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 4px;
    min-width: 0;
    overflow: hidden;
  }

  .marquee-container {
    flex: 1;
    overflow: hidden;
    white-space: nowrap;
    min-width: 0;
  }

  .marquee-text {
    display: inline-block;
    font-size: 11px;
    color: color-mix(in oklch, var(--color-foreground) 75%, transparent);
  }

  .marquee-text.animate {
    animation: marquee 8s linear infinite;
  }

  @keyframes marquee {
    0% { transform: translateX(0); }
    10% { transform: translateX(0); }
    90% { transform: translateX(calc(-100% + 60px)); }
    100% { transform: translateX(calc(-100% + 60px)); }
  }

  /* 编辑按钮 */
  .edit-btn {
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 16px;
    height: 16px;
    padding: 0;
    border: none;
    border-radius: 3px;
    background: transparent;
    color: color-mix(in oklch, var(--color-foreground) 40%, transparent);
    cursor: pointer;
    transition: color 0.15s, background 0.15s;
  }

  .edit-btn:hover {
    color: var(--color-foreground);
    background: color-mix(in oklch, var(--color-foreground) 10%, transparent);
  }

  /* 编辑模式输入框 */
  .note-edit {
    flex: 1;
    min-width: 0;
  }

  .note-input {
    width: 100%;
    padding: 2px 6px;
    border: 1px solid color-mix(in oklch, var(--color-foreground) 25%, transparent);
    border-radius: 4px;
    background: color-mix(in oklch, var(--color-foreground) 8%, transparent);
    color: var(--color-foreground);
    font-size: 10px;
    outline: none;
    box-sizing: border-box;
  }

  .note-input::placeholder {
    color: color-mix(in oklch, var(--color-foreground) 35%, transparent);
  }

  /* 无任务文本时占位 */
  .spacer {
    flex: 1;
  }

  /* 重置按钮（暂停时显示） */
  .reset-btn {
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    padding: 0;
    border: none;
    border-radius: 3px;
    background: transparent;
    color: color-mix(in oklch, var(--color-foreground) 60%, transparent);
    cursor: pointer;
    transition: color 0.15s, background 0.15s;
  }

  .reset-btn:hover {
    color: var(--color-foreground);
    background: color-mix(in oklch, var(--color-foreground) 10%, transparent);
  }

  /* 倒计时时间 */
  .time-display {
    flex-shrink: 0;
    font-size: 14px;
    font-weight: 600;
    color: var(--color-foreground);
    font-variant-numeric: tabular-nums;
    letter-spacing: 0.02em;
  }

  /* 悬浮控件 */
  .hover-controls {
    position: absolute;
    top: 2px;
    right: 4px;
    display: flex;
    gap: 2px;
    z-index: 10;
  }

  .hover-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 18px;
    height: 18px;
    padding: 0;
    border: none;
    border-radius: 3px;
    background: color-mix(in oklch, var(--color-background) 80%, transparent);
    color: color-mix(in oklch, var(--color-foreground) 60%, transparent);
    cursor: pointer;
    transition: color 0.15s, background 0.15s;
    backdrop-filter: blur(4px);
  }

  .hover-btn:hover {
    color: var(--color-foreground);
    background: var(--color-hover);
  }

  .hover-btn.close:hover {
    color: var(--color-background);
    background: var(--color-focus-round);
  }
</style>
