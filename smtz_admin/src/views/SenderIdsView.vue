<script setup>
import { reactive } from 'vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import { useStore } from '../store/useStore'
import { formatDate } from '../utils/format'

const { state, requestSenderId } = useStore()

const form = reactive({ name: '', sample: '' })

function handleSubmit() {
  if (!form.name.trim()) return
  requestSenderId({ name: form.name, sample: form.sample })
  form.name = ''
  form.sample = ''
}
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[380px_1fr]">
    <div class="space-y-5">
      <Panel title="Request Sender ID">
        <div class="space-y-5">
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Sender Name</label>
            <input
              v-model="form.name"
              type="text"
              maxlength="11"
              placeholder="e.g. MYBRAND"
              class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm uppercase text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 placeholder:normal-case focus:border-azure-500/50 focus:bg-white/[0.05]"
            />
            <p class="mt-2 text-xs text-zinc-500">Max 11 characters, letters &amp; numbers only, no spaces</p>
          </div>
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Sample Message</label>
            <textarea
              v-model="form.sample"
              rows="3"
              placeholder="Example message that will be sent using this sender ID..."
              class="w-full resize-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
            ></textarea>
            <p class="mt-2 text-xs text-zinc-500">Helps our team review your request</p>
          </div>
          <button
            type="button"
            :disabled="!form.name.trim()"
            class="w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
            @click="handleSubmit"
          >
            Submit Request
          </button>
        </div>
      </Panel>

      <div class="rounded-2xl border border-azure-500/20 bg-azure-500/[0.06] p-5">
        <p class="text-sm font-semibold text-azure-300">Approval process</p>
        <p class="mt-1.5 text-sm text-zinc-400">
          Sender IDs are reviewed by our team within 1–2 weeks. You'll see the status update here once processed.
        </p>
      </div>
    </div>

    <Panel>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-white/[0.06] text-xs uppercase tracking-wider text-zinc-500">
              <th class="pb-3 pr-4 font-medium">Sender</th>
              <th class="pb-3 pr-4 font-medium">Sample Message</th>
              <th class="pb-3 pr-4 font-medium">Status</th>
              <th class="pb-3 font-medium">Requested</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="s in state.senderIds"
              :key="s.name"
              class="border-b border-white/[0.04] last:border-0 hover:bg-white/[0.02]"
            >
              <td class="py-3.5 pr-4 font-mono font-semibold text-zinc-100">{{ s.name }}</td>
              <td class="py-3.5 pr-4 text-zinc-500">{{ s.sample }}</td>
              <td class="py-3.5 pr-4"><Badge :status="s.status" /></td>
              <td class="py-3.5 tabular text-zinc-500">{{ formatDate(s.requested) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Panel>
  </div>
</template>
