<script lang="ts">
  import { settings } from '$lib/stores/settings';
  import { setSetting } from '$lib/ipc';
  import * as m from '$paraglide/messages.js';

  interface Props {
    compact?: boolean;
  }

  let { compact = false }: Props = $props();

  let localValue = $state($settings.current_task_note);
  let debounceTimer: ReturnType<typeof setTimeout> | null = null;
  let isFocused = $state(false);
  let compactEditing = $state(false);
  let inputEl: HTMLInputElement | undefined = $state();

  // 外部 store 变更时同步本地值
  $effect(() => {
    localValue = $settings.current_task_note;
  });

  function handleInput(e: Event) {
    const target = e.target as HTMLInputElement;
    localValue = target.value;

    if (debounceTimer) clearTimeout(debounceTimer);
    debounceTimer = setTimeout(async () => {
      const updated = await setSetting('current_task_note', localValue);
      settings.set(updated);
    }, 300);
  }

  function enterCompactEdit() {
    compactEditing = true;
    // 等 DOM 更新后聚焦输入框
    requestAnimationFrame(() => inputEl?.focus());
  }

  function exitCompactEdit() {
    compactEditing = false;
    isFocused = false;
  }
</script>

{#if compact && !compactEditing}
  <!-- Compact 模式：只读标签 + 编辑按钮 -->
  <div class="task-note-compact">
    <span class="label-text" class:empty={!localValue}>
      {localValue || m.task_note_placeholder()}
    </span>
    <button class="edit-btn" onclick={enterCompactEdit} aria-label="Edit task note">
      <svg width="10" height="10" viewBox="0 0 16 16" fill="currentColor">
        <path d="M12.146.854a.5.5 0 0 1 .708 0l2.292 2.292a.5.5 0 0 1 0 .708L5.707 13.293a.5.5 0 0 1-.198.13l-3.5 1.25a.5.5 0 0 1-.632-.632l1.25-3.5a.5.5 0 0 1 .13-.198L12.146.854zM13 2.207 11.293 3.914l.793.793L13.793 3 13 2.207zM4.06 11.647l-.884 2.476 2.476-.884L11.44 7.45l-1.59-1.59L4.06 11.647z"/>
      </svg>
    </button>
  </div>
{:else}
  <!-- 正常模式 / compact 编辑态 -->
  <div class="task-note-input" class:compact>
    <input
      bind:this={inputEl}
      type="text"
      maxlength={100}
      value={localValue}
      oninput={handleInput}
      onfocus={() => (isFocused = true)}
      onblur={() => {
        isFocused = false;
        if (compact) exitCompactEdit();
      }}
      onkeydown={(e) => {
        if (e.key === 'Enter' || e.key === 'Escape') {
          (e.target as HTMLInputElement).blur();
        }
      }}
      placeholder={m.task_note_placeholder()}
      class="note-input"
      class:editing={isFocused}
    />
  </div>
{/if}

<style>
  .task-note-input {
    width: 100%;
    display: flex;
    justify-content: center;
    padding: 0 12px;
    box-sizing: border-box;
  }

  .task-note-input.compact {
    padding: 0 8px;
  }

  .note-input {
    width: 100%;
    max-width: 200px;
    padding: 4px 8px;
    border: 1px solid transparent;
    border-radius: 6px;
    background: transparent;
    color: var(--color-foreground);
    font-size: 11px;
    text-align: center;
    outline: none;
    transition: border-color 0.15s, background 0.15s;
  }

  .compact .note-input {
    font-size: 10px;
    max-width: 160px;
    padding: 3px 6px;
  }

  .note-input::placeholder {
    color: color-mix(in oklch, var(--color-foreground) 35%, transparent);
  }

  .note-input:hover:not(.editing) {
    background: color-mix(in oklch, var(--color-foreground) 5%, transparent);
  }

  .note-input.editing {
    border-color: color-mix(in oklch, var(--color-foreground) 25%, transparent);
    background: color-mix(in oklch, var(--color-foreground) 8%, transparent);
  }

  /* Compact 只读标签 + 编辑按钮 */
  .task-note-compact {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 0 8px;
  }

  .label-text {
    font-size: 10px;
    color: color-mix(in oklch, var(--color-foreground) 70%, transparent);
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 160px;
  }

  .label-text.empty {
    color: color-mix(in oklch, var(--color-foreground) 30%, transparent);
    font-style: italic;
  }

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
</style>
