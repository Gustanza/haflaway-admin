<script setup>
import { reactive } from 'vue'
import Panel from '../components/ui/Panel.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'
import { formatDate } from '../utils/format'

const { state, saveTemplate } = useStore()

const form = reactive({ name: '', body: '' })

function handleSave() {
  if (!form.name.trim() || !form.body.trim()) return
  saveTemplate({ name: form.name, body: form.body })
  form.name = ''
  form.body = ''
}
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[380px_1fr]">
    <Panel title="New Template">
      <div class="space-y-5">
        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">
            Name <span class="text-azure-400">*</span>
          </label>
          <input
            v-model="form.name"
            type="text"
            placeholder="e.g. Promo Offer"
            class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          />
        </div>
        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">
            Message Body <span class="text-azure-400">*</span>
          </label>
          <textarea
            v-model="form.body"
            rows="6"
            placeholder="Your message text..."
            class="w-full resize-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          ></textarea>
        </div>
        <button
          type="button"
          :disabled="!form.name.trim() || !form.body.trim()"
          class="w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
          @click="handleSave"
        >
          Save Template
        </button>
      </div>
    </Panel>

    <Panel>
      <div v-if="!state.templates.length" class="grid h-full min-h-[280px] place-items-center py-10">
        <div class="text-center">
          <div class="mx-auto grid h-12 w-12 place-items-center rounded-2xl bg-white/[0.04] text-zinc-600">
            <AppIcon name="document" class="h-6 w-6" />
          </div>
          <p class="mt-4 text-sm text-zinc-500">No message templates yet</p>
        </div>
      </div>
      <div v-else class="divide-y divide-white/[0.05]">
        <div v-for="t in state.templates" :key="t.id" class="py-4 first:pt-0 last:pb-0">
          <div class="flex items-center justify-between">
            <p class="text-sm font-semibold text-zinc-100">{{ t.name }}</p>
            <p class="text-xs text-zinc-600">{{ formatDate(t.createdAt) }}</p>
          </div>
          <p class="mt-1.5 text-sm text-zinc-500">{{ t.body }}</p>
        </div>
      </div>
    </Panel>
  </div>
</template>
