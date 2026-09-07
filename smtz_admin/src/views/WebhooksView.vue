<script setup>
import { ref } from 'vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import { useStore } from '../store/useStore'
import { truncate } from '../utils/format'

const { state, registerWebhook, toggleWebhook, deleteWebhook } = useStore()

const url = ref('')

function handleRegister() {
  if (!url.value.trim()) return
  registerWebhook(url.value.trim())
  url.value = ''
}
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[380px_1fr]">
    <div class="space-y-5">
      <Panel title="Register Webhook">
        <div class="space-y-5">
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Endpoint URL</label>
            <input
              v-model="url"
              type="url"
              placeholder="https://yourapp.com/webhook"
              class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 font-mono text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
            />
          </div>
          <button
            type="button"
            :disabled="!url.trim()"
            class="w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
            @click="handleRegister"
          >
            Register
          </button>
        </div>
      </Panel>

      <Panel title="Webhook payloads">
        <p class="text-sm text-zinc-500">
          Signed with
          <code class="rounded bg-white/[0.06] px-1.5 py-0.5 font-mono text-xs text-zinc-300">X-Wasambazie-Signature</code>
          (HMAC-SHA256).
        </p>
        <p class="mt-2 text-sm text-zinc-500">
          Event:
          <code class="rounded bg-white/[0.06] px-1.5 py-0.5 font-mono text-xs text-zinc-300">delivery.batch.finalized</code>
        </p>
      </Panel>
    </div>

    <Panel>
      <div v-if="!state.webhooks.length" class="grid h-full min-h-[280px] place-items-center py-10">
        <p class="text-sm text-zinc-500">No webhooks registered yet</p>
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-white/[0.06] text-xs uppercase tracking-wider text-zinc-500">
              <th class="pb-3 pr-4 font-medium">URL</th>
              <th class="pb-3 pr-4 font-medium">Status</th>
              <th class="pb-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="w in state.webhooks"
              :key="w.id"
              class="border-b border-white/[0.04] last:border-0 hover:bg-white/[0.02]"
            >
              <td class="py-3.5 pr-4 font-mono text-zinc-300">{{ truncate(w.url, 34) }}</td>
              <td class="py-3.5 pr-4"><Badge :status="w.status" /></td>
              <td class="py-3.5">
                <div class="flex items-center gap-4">
                  <button type="button" class="text-sm font-medium text-azure-400 hover:text-azure-300">
                    Logs
                  </button>
                  <button
                    type="button"
                    class="text-sm font-medium text-zinc-400 hover:text-zinc-200"
                    @click="toggleWebhook(w.id)"
                  >
                    {{ w.status === 'Active' ? 'Disable' : 'Enable' }}
                  </button>
                  <button
                    type="button"
                    class="text-sm font-medium text-rose-400 hover:text-rose-300"
                    @click="deleteWebhook(w.id)"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Panel>
  </div>
</template>
