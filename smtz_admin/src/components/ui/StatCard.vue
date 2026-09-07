<script setup>
import AppIcon from '../AppIcon.vue'

defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  caption: { type: String, default: '' },
  icon: { type: String, required: true },
  tone: { type: String, default: 'azure' },
})

const toneMap = {
  azure: 'bg-azure-400/10 text-azure-300 ring-azure-400/20',
  violet: 'bg-violet-400/10 text-violet-300 ring-violet-400/20',
  emerald: 'bg-emerald-400/10 text-emerald-300 ring-emerald-400/20',
  zinc: 'bg-white/[0.06] text-zinc-300 ring-white/10',
}
</script>

<template>
  <div
    class="rounded-2xl border border-white/[0.08] bg-white/[0.03] p-5 backdrop-blur-sm transition-colors hover:border-white/[0.14]"
  >
    <div class="flex items-start justify-between">
      <span class="text-sm text-zinc-400">{{ label }}</span>
      <span class="grid h-9 w-9 place-items-center rounded-xl ring-1 ring-inset" :class="toneMap[tone]">
        <AppIcon :name="icon" class="h-5 w-5" />
      </span>
    </div>
    <div class="mt-4 tabular font-mono text-3xl font-semibold text-zinc-50">{{ value }}</div>
    <div v-if="caption" class="mt-1 text-sm text-zinc-500">{{ caption }}</div>
  </div>
</template>
