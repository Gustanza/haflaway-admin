<script setup>
import { ref, computed } from 'vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'
import { formatDateTime } from '../utils/format'

const { state } = useStore()

const senderFilter = ref('all')
const statusFilter = ref('all')

const senderOptions = computed(() => [...new Set(state.messages.map((m) => m.senderId))])

const filtered = computed(() =>
  state.messages.filter((m) => {
    if (senderFilter.value !== 'all' && m.senderId !== senderFilter.value) return false
    if (statusFilter.value !== 'all' && m.status !== statusFilter.value) return false
    return true
  }),
)

const selectClass =
  'rounded-xl border border-white/[0.08] bg-white/[0.03] px-3 py-2 text-sm text-zinc-100 outline-none focus:border-azure-500/50'
const inputClass = selectClass
</script>

<template>
  <div class="space-y-5">
    <Panel>
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div class="flex flex-wrap items-end gap-3">
          <div>
            <label class="mb-1.5 block text-xs font-medium text-zinc-400">Sender ID</label>
            <select v-model="senderFilter" :class="selectClass">
              <option value="all">All Senders</option>
              <option v-for="s in senderOptions" :key="s" :value="s">{{ s }}</option>
            </select>
          </div>
          <div>
            <label class="mb-1.5 block text-xs font-medium text-zinc-400">Status</label>
            <select v-model="statusFilter" :class="selectClass">
              <option value="all">All Statuses</option>
              <option value="Delivered">Delivered</option>
              <option value="Failed">Failed</option>
            </select>
          </div>
          <div>
            <label class="mb-1.5 block text-xs font-medium text-zinc-400">From</label>
            <input type="date" :class="inputClass" />
          </div>
          <div>
            <label class="mb-1.5 block text-xs font-medium text-zinc-400">To</label>
            <input type="date" :class="inputClass" />
          </div>
        </div>
        <div class="flex gap-2">
          <button
            type="button"
            class="flex items-center gap-2 rounded-xl border border-white/[0.08] bg-white/[0.03] px-3.5 py-2 text-sm font-medium text-zinc-300 transition-colors hover:border-white/[0.16] hover:text-white"
          >
            <AppIcon name="download" class="h-4 w-4" />
            Excel
          </button>
          <button
            type="button"
            class="flex items-center gap-2 rounded-xl border border-white/[0.08] bg-white/[0.03] px-3.5 py-2 text-sm font-medium text-zinc-300 transition-colors hover:border-white/[0.16] hover:text-white"
          >
            <AppIcon name="document" class="h-4 w-4" />
            PDF
          </button>
        </div>
      </div>
    </Panel>

    <p class="text-sm text-zinc-500">{{ filtered.length }} message(s) in selected range</p>

    <Panel>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-white/[0.06] text-xs uppercase tracking-wider text-zinc-500">
              <th class="pb-3 pr-4 font-medium">Recipient</th>
              <th class="pb-3 pr-4 font-medium">Sender ID</th>
              <th class="pb-3 pr-4 font-medium">Message</th>
              <th class="pb-3 pr-4 font-medium">Seg</th>
              <th class="pb-3 pr-4 font-medium">Status</th>
              <th class="pb-3 pr-4 font-medium">Sent At</th>
              <th class="pb-3 font-medium">Delivered At</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="m in filtered"
              :key="m.id"
              class="border-b border-white/[0.04] last:border-0 hover:bg-white/[0.02]"
            >
              <td class="py-3.5 pr-4 font-mono text-zinc-300">{{ m.recipient }}</td>
              <td class="py-3.5 pr-4 text-zinc-400">{{ m.senderId }}</td>
              <td class="max-w-[220px] truncate py-3.5 pr-4 text-zinc-400">{{ m.message }}</td>
              <td class="py-3.5 pr-4 tabular text-zinc-500">{{ m.seg }}</td>
              <td class="py-3.5 pr-4"><Badge :status="m.status" /></td>
              <td class="py-3.5 pr-4 tabular font-mono text-zinc-500">{{ formatDateTime(m.sentAt) }}</td>
              <td class="py-3.5 tabular font-mono text-zinc-500">{{ formatDateTime(m.deliveredAt) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Panel>
  </div>
</template>
