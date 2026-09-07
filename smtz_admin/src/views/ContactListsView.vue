<script setup>
import { reactive } from 'vue'
import Panel from '../components/ui/Panel.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'
import { formatDate } from '../utils/format'

const { state, createContactList } = useStore()

const form = reactive({ name: '', description: '' })

function handleCreate() {
  if (!form.name.trim()) return
  createContactList({ name: form.name, description: form.description })
  form.name = ''
  form.description = ''
}
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[380px_1fr]">
    <Panel title="New Contact List">
      <div class="space-y-5">
        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">
            List Name <span class="text-azure-400">*</span>
          </label>
          <input
            v-model="form.name"
            type="text"
            placeholder="e.g. August Campaign"
            class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          />
        </div>
        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">Description</label>
          <input
            v-model="form.description"
            type="text"
            placeholder="Optional"
            class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          />
        </div>
        <button
          type="button"
          :disabled="!form.name.trim()"
          class="w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
          @click="handleCreate"
        >
          Create List
        </button>
      </div>
    </Panel>

    <Panel>
      <div v-if="!state.contactLists.length" class="grid h-full min-h-[280px] place-items-center py-10">
        <div class="text-center">
          <div class="mx-auto grid h-12 w-12 place-items-center rounded-2xl bg-white/[0.04] text-zinc-600">
            <AppIcon name="users" class="h-6 w-6" />
          </div>
          <p class="mt-4 text-sm text-zinc-500">No contact lists yet</p>
        </div>
      </div>
      <div v-else class="divide-y divide-white/[0.05]">
        <div v-for="c in state.contactLists" :key="c.id" class="flex items-center justify-between py-4 first:pt-0 last:pb-0">
          <div>
            <p class="text-sm font-semibold text-zinc-100">{{ c.name }}</p>
            <p class="mt-0.5 text-xs text-zinc-500">{{ c.description || 'No description' }}</p>
          </div>
          <div class="text-right">
            <p class="tabular font-mono text-sm text-zinc-300">{{ c.contacts }} contacts</p>
            <p class="mt-0.5 text-xs text-zinc-600">{{ formatDate(c.createdAt) }}</p>
          </div>
        </div>
      </div>
    </Panel>
  </div>
</template>
