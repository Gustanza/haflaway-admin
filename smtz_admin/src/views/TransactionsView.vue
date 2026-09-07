<script setup>
import Panel from '../components/ui/Panel.vue'
import { useStore } from '../store/useStore'
import { formatDateTime, truncate } from '../utils/format'

const { state } = useStore()
</script>

<template>
  <Panel>
    <div v-if="!state.transactions.length" class="grid h-full min-h-[280px] place-items-center py-10">
      <p class="text-sm text-zinc-500">No transactions yet</p>
    </div>
    <div v-else class="divide-y divide-white/[0.04]">
      <div
        v-for="t in state.transactions"
        :key="t.id"
        class="flex items-center gap-4 py-3.5 first:pt-0 last:pb-0"
      >
        <span class="w-16 shrink-0 text-sm font-semibold text-rose-400">{{ t.type }}</span>
        <span class="w-14 shrink-0 tabular font-mono text-sm font-semibold text-rose-400">{{ t.amount }}</span>
        <span class="min-w-0 flex-1 truncate font-mono text-sm text-zinc-400">{{ truncate(t.reference, 40) }}</span>
        <span class="shrink-0 tabular font-mono text-sm text-zinc-600">{{ formatDateTime(t.date) }}</span>
      </div>
    </div>
  </Panel>
</template>
