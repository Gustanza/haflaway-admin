<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import StatCard from '../components/ui/StatCard.vue'
import ActionCard from '../components/ui/ActionCard.vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import { useStore } from '../store/useStore'
import { formatDateTime, truncate } from '../utils/format'

const { state } = useStore()

const recent = computed(() => state.messages.slice(0, 6))
</script>

<template>
  <div class="space-y-8">
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        label="SMS Balance"
        :value="state.account.balanceSms.toLocaleString()"
        caption="Available credits"
        icon="dollar"
        tone="azure"
      />
      <StatCard
        label="Total Messages"
        :value="state.account.totalMessages.toLocaleString()"
        caption="All time"
        icon="chat"
        tone="violet"
      />
      <StatCard
        label="Sent Today"
        :value="String(state.account.sentToday)"
        caption="Messages sent today"
        icon="send"
        tone="emerald"
      />
      <StatCard
        label="Pending Top-Ups"
        :value="String(state.account.pendingTopUps)"
        caption="Awaiting confirmation"
        icon="clock"
        tone="zinc"
      />
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
      <ActionCard
        title="Send SMS"
        description="Send a new message batch"
        icon="send"
        to="/send-sms"
        primary
      />
      <ActionCard title="Top Up" description="Add more SMS credits" icon="dollar" to="/top-up" />
      <ActionCard
        title="Delivery Reports"
        description="View batch delivery results"
        icon="chart"
        to="/delivery-reports"
      />
    </div>

    <Panel>
      <div class="mb-5 flex items-center justify-between">
        <h2 class="text-[15px] font-semibold text-zinc-100">Recent Messages</h2>
        <RouterLink to="/messages" class="text-sm font-medium text-azure-400 hover:text-azure-300">
          View all
        </RouterLink>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-white/[0.06] text-xs uppercase tracking-wider text-zinc-500">
              <th class="pb-3 pr-4 font-medium">Recipient</th>
              <th class="pb-3 pr-4 font-medium">Sender ID</th>
              <th class="pb-3 pr-4 font-medium">Message</th>
              <th class="pb-3 pr-4 font-medium">Status</th>
              <th class="pb-3 font-medium">Sent At</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="m in recent"
              :key="m.id"
              class="border-b border-white/[0.04] last:border-0 hover:bg-white/[0.02]"
            >
              <td class="py-3.5 pr-4 font-mono text-zinc-300">{{ m.recipient }}</td>
              <td class="py-3.5 pr-4 text-zinc-400">{{ m.senderId }}</td>
              <td class="py-3.5 pr-4 text-zinc-400">{{ truncate(m.message) }}</td>
              <td class="py-3.5 pr-4"><Badge :status="m.status" /></td>
              <td class="py-3.5 tabular font-mono text-zinc-500">{{ formatDateTime(m.sentAt) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Panel>
  </div>
</template>
