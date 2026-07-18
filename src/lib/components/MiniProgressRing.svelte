<script lang="ts">
  // 32px 圆形进度环 + 内嵌播放/暂停按钮
  import { fade } from 'svelte/transition';

  interface Props {
    /** 进度值 0-1 */
    progress: number;
    /** 进度环颜色 */
    color: string;
    /** 是否正在运行 */
    isRunning: boolean;
    /** 点击播放/暂停 */
    onToggle: () => void;
  }

  let { progress, color, isRunning, onToggle }: Props = $props();

  // SVG 圆环参数
  const SIZE = 32;
  const STROKE = 2.5;
  const RADIUS = (SIZE - STROKE) / 2;
  const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

  let dashOffset = $derived(CIRCUMFERENCE * (1 - progress));
</script>

<button class="mini-ring" onclick={onToggle} aria-label={isRunning ? 'Pause' : 'Play'}>
  <svg width={SIZE} height={SIZE} viewBox="0 0 {SIZE} {SIZE}">
    <!-- 背景环 -->
    <circle
      cx={SIZE / 2}
      cy={SIZE / 2}
      r={RADIUS}
      fill="none"
      stroke="color-mix(in oklch, {color} 20%, transparent)"
      stroke-width={STROKE}
    />
    <!-- 进度弧 -->
    <circle
      cx={SIZE / 2}
      cy={SIZE / 2}
      r={RADIUS}
      fill="none"
      stroke={color}
      stroke-width={STROKE}
      stroke-linecap="round"
      stroke-dasharray={CIRCUMFERENCE}
      stroke-dashoffset={dashOffset}
      transform="rotate(-90 {SIZE / 2} {SIZE / 2})"
    />
  </svg>
  <!-- 播放/暂停图标叠加在圆环中心 -->
  <span class="ring-icon">
    {#key isRunning}
      <span class="icon-inner" in:fade={{ duration: 100 }}>
        {#if isRunning}
          <!-- 暂停图标 -->
          <svg width="10" height="10" viewBox="0 0 24 24">
            <rect x="5" y="4" width="4.5" height="16" rx="1" fill="currentColor" />
            <rect x="14.5" y="4" width="4.5" height="16" rx="1" fill="currentColor" />
          </svg>
        {:else}
          <!-- 播放图标 -->
          <svg width="10" height="10" viewBox="0 0 24 24">
            <polygon points="7,3 21,12 7,21" fill="currentColor" />
          </svg>
        {/if}
      </span>
    {/key}
  </span>
</button>

<style>
  .mini-ring {
    position: relative;
    width: 32px;
    height: 32px;
    padding: 0;
    border: none;
    border-radius: 50%;
    background: transparent;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: opacity 0.15s;
  }

  .mini-ring:hover {
    opacity: 0.85;
  }

  .ring-icon {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-foreground);
  }

  .icon-inner {
    display: flex;
    align-items: center;
    justify-content: center;
  }
</style>
