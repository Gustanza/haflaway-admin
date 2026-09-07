<script setup>
import { ref } from 'vue'
import Panel from '../components/ui/Panel.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'
import { formatDateTime } from '../utils/format'

const { state } = useStore()

const expanded = ref(new Set())

function toggle(id) {
  const next = new Set(expanded.value)
  next.has(id) ? next.delete(id) : next.add(id)
  expanded.value = next
}
</script>

<template>
  <Panel>
    <div class="divide-y divide-white/[0.05]">
      <div v-for="r in state.deliveryReports" :key="r.id">
        <button
          type="button"
          class="flex w-full items-center gap-4 py-4 text-left transition-colors hover:bg-white/[0.02]"
          @click="toggle(r.id)"
        >
          <AppIcon
            name="chevron-right"
            class="h-4 w-4 shrink-0 text-zinc-500 transition-transform"
            :class="{ 'rotate-90': expanded.has(r.id) }"
          />
          <span class="min-w-0 flex-1 truncate font-mono text-sm text-zinc-400">{{ r.id }}</span>
          <span
            class="shrink-0 rounded-full bg-emerald-400/10 px-2.5 py-1 text-xs font-medium text-emerald-300 ring-1 ring-inset ring-emerald-400/20"
          >
            {{ r.delivered }} delivered
          </span>
          <span
            class="shrink-0 rounded-full bg-rose-400/10 px-2.5 py-1 text-xs font-medium text-rose-300 ring-1 ring-inset ring-rose-400/20"
          >
            {{ r.failed }} failed
          </span>
          <span class="hidden shrink-0 text-sm tabular text-zinc-500 sm:block">{{ r.total }} total</span>
          <span class="hidden shrink-0 tabular font-mono text-sm text-zinc-600 md:block">
            {{ formatDateTime(r.date) }}
          </span>
        </button>

        <div v-if="expanded.has(r.id)" class="ml-8 mb-4 rounded-xl border border-white/[0.06] bg-white/[0.02] p-4 text-sm text-zinc-500">
          Batch {{ r.id }} · {{ r.total }} message(s) · sent {{ formatDateTime(r.date) }}
        </div>
      </div>
    </div>
  </Panel>
</template>
