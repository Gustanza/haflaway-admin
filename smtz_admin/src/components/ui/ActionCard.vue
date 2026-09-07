<script setup>
import { RouterLink } from 'vue-router'
import AppIcon from '../AppIcon.vue'

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  icon: { type: String, required: true },
  to: { type: String, required: true },
  primary: { type: Boolean, default: false },
})
</script>

<template>
  <RouterLink
    :to="to"
    class="group flex items-center gap-4 rounded-2xl border p-5 transition-all"
    :class="
      primary
        ? 'border-azure-500/40 bg-gradient-to-br from-azure-500 to-azure-600 shadow-[0_8px_30px_-8px_rgba(28,120,245,0.55)] hover:shadow-[0_10px_36px_-6px_rgba(28,120,245,0.65)]'
        : 'border-white/[0.08] bg-white/[0.03] hover:border-white/[0.14] hover:bg-white/[0.045]'
    "
  >
    <span
      class="grid h-11 w-11 shrink-0 place-items-center rounded-xl ring-1 ring-inset transition-transform group-hover:scale-105"
      :class="primary ? 'bg-white/15 text-white ring-white/20' : 'bg-white/[0.06] text-azure-300 ring-white/10'"
    >
      <AppIcon :name="icon" class="h-5 w-5" />
    </span>
    <span class="min-w-0">
      <span class="block truncate text-[15px] font-semibold" :class="primary ? 'text-white' : 'text-zinc-100'">
        {{ title }}
      </span>
      <span class="block truncate text-sm" :class="primary ? 'text-white/80' : 'text-zinc-500'">
        {{ description }}
      </span>
    </span>
  </RouterLink>
</template>
