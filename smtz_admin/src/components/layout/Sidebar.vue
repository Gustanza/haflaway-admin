<script setup>
import { RouterLink } from 'vue-router'
import AppIcon from '../AppIcon.vue'
import { useStore } from '../../store/useStore'

const { state } = useStore()

const groups = [
  {
    label: 'Overview',
    items: [{ to: '/', label: 'Dashboard', icon: 'home' }],
  },
  {
    label: 'Messaging',
    items: [
      { to: '/send-sms', label: 'Send SMS', icon: 'send' },
      { to: '/messages', label: 'Messages', icon: 'chat' },
      { to: '/contact-lists', label: 'Contact Lists', icon: 'users' },
      { to: '/templates', label: 'Templates', icon: 'document' },
      { to: '/delivery-reports', label: 'Delivery Reports', icon: 'chart' },
    ],
  },
  {
    label: 'Account',
    items: [
      { to: '/sender-ids', label: 'Sender IDs', icon: 'badge' },
      { to: '/api-keys', label: 'API Keys', icon: 'key' },
      { to: '/webhooks', label: 'Webhooks', icon: 'link' },
    ],
  },
  {
    label: 'Billing',
    items: [
      { to: '/top-up', label: 'Top Up', icon: 'dollar' },
      { to: '/transactions', label: 'Transactions', icon: 'receipt' },
    ],
  },
]

const initial = state.user.name.charAt(0)
</script>

<template>
  <aside
    class="fixed inset-y-0 left-0 z-20 flex w-64 flex-col border-r border-white/[0.07] bg-ink-900/80 backdrop-blur-xl"
  >
    <div class="flex items-center gap-2.5 px-6 py-6">
      <span
        class="grid h-8 w-8 place-items-center rounded-lg bg-gradient-to-br from-azure-400 to-azure-600 text-sm font-bold text-white shadow-[0_0_20px_-4px_rgba(28,120,245,0.7)]"
      >
        S
      </span>
      <span class="text-lg font-bold tracking-tight text-zinc-50">SMTZ Admin</span>
    </div>

    <nav class="flex-1 overflow-y-auto px-3 pb-4">
      <div v-for="group in groups" :key="group.label" class="mb-5">
        <p class="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-zinc-600">
          {{ group.label }}
        </p>
        <RouterLink
          v-for="item in group.items"
          :key="item.to"
          :to="item.to"
          class="mb-0.5 flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-zinc-400 transition-colors hover:bg-white/[0.04] hover:text-zinc-100 [&.router-link-exact-active]:bg-gradient-to-r [&.router-link-exact-active]:from-azure-500 [&.router-link-exact-active]:to-azure-600 [&.router-link-exact-active]:text-white [&.router-link-exact-active]:shadow-[0_4px_16px_-4px_rgba(28,120,245,0.5)]"
        >
          <AppIcon :name="item.icon" class="h-[18px] w-[18px] shrink-0" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </div>
    </nav>

    <div class="border-t border-white/[0.07] p-4">
      <div class="flex items-center gap-3 rounded-xl px-2 py-2">
        <span
          class="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-gradient-to-br from-azure-400 to-azure-600 text-sm font-semibold text-white"
        >
          {{ initial }}
        </span>
        <span class="min-w-0 flex-1">
          <span class="block truncate text-sm font-semibold text-zinc-100">{{ state.user.name }}</span>
          <span class="block truncate text-xs text-zinc-500">{{ state.user.email }}</span>
        </span>
      </div>
      <button
        type="button"
        class="mt-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-zinc-500 transition-colors hover:bg-white/[0.04] hover:text-rose-300"
      >
        <AppIcon name="logout" class="h-[18px] w-[18px]" />
        Sign out
      </button>
    </div>
  </aside>
</template>
