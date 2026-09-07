<script setup>
import { useRoute } from 'vue-router'
import Sidebar from '../components/layout/Sidebar.vue'
import { useStore } from '../store/useStore'

const route = useRoute()
const { state } = useStore()
</script>

<template>
  <div class="min-h-screen">
    <Sidebar />

    <div class="pl-64">
      <header class="sticky top-0 z-10 border-b border-white/[0.06] bg-ink-950/70 backdrop-blur-xl">
        <div class="flex items-center justify-between px-8 py-6">
          <div>
            <h1 class="text-2xl font-bold tracking-tight text-zinc-50">{{ route.meta.title }}</h1>
            <p class="mt-0.5 text-sm text-zinc-500">
              <template v-if="route.name === 'dashboard'">Welcome back, {{ state.user.name }}</template>
              <template v-else>{{ route.meta.subtitle }}</template>
            </p>
          </div>
          <div class="text-right">
            <p class="text-xs uppercase tracking-wider text-zinc-500">Balance</p>
            <p class="tabular font-mono text-xl font-bold text-azure-400">
              {{ state.account.balanceSms.toLocaleString() }} SMS
            </p>
          </div>
        </div>
      </header>

      <main class="px-8 py-8">
        <RouterView />
      </main>
    </div>
  </div>
</template>
