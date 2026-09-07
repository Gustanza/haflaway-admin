<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, required: true },
})

const tones = {
  Delivered: 'text-emerald-300 bg-emerald-400/10 ring-emerald-400/20',
  Approved: 'text-emerald-300 bg-emerald-400/10 ring-emerald-400/20',
  Active: 'text-emerald-300 bg-emerald-400/10 ring-emerald-400/20',
  Confirmed: 'text-emerald-300 bg-emerald-400/10 ring-emerald-400/20',
  Failed: 'text-rose-300 bg-rose-400/10 ring-rose-400/20',
  Revoked: 'text-rose-300 bg-rose-400/10 ring-rose-400/20',
  Disabled: 'text-zinc-400 bg-zinc-400/10 ring-zinc-400/20',
  Pending: 'text-azure-300 bg-azure-400/10 ring-azure-400/20',
  Processing: 'text-azure-300 bg-azure-400/10 ring-azure-400/20',
}

const classes = computed(() => tones[props.status] ?? 'text-zinc-300 bg-zinc-400/10 ring-zinc-400/20')
</script>

<template>
  <span
    class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset"
    :class="classes"
  >
    <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
    {{ status }}
  </span>
</template>
