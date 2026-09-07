<script setup>
import { ref, computed } from 'vue'
import Panel from '../components/ui/Panel.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'

const { state, sendSms } = useStore()

const mode = ref('manual')
const senderId = ref('')
const recipients = ref('')
const message = ref('')
const sentNotice = ref(0)

const segments = computed(() => Math.max(1, Math.ceil((message.value.length || 1) / 160)))
const recipientCount = computed(
  () => recipients.value.split(/[,\n]/).map((r) => r.trim()).filter(Boolean).length,
)
const canSend = computed(() => recipientCount.value > 0 && message.value.trim().length > 0)

function handleSend() {
  if (!recipients.value.trim() || !message.value.trim()) return
  const count = sendSms({ senderId: senderId.value, recipients: recipients.value, message: message.value })
  sentNotice.value = count
  recipients.value = ''
  message.value = ''
  setTimeout(() => (sentNotice.value = 0), 4000)
}
</script>

<template>
  <div class="mx-auto max-w-2xl">
    <Panel title="New Message">
      <div
        v-if="sentNotice"
        class="mb-5 rounded-xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-300"
      >
        Sent to {{ sentNotice }} recipient{{ sentNotice > 1 ? 's' : '' }}.
      </div>

      <div class="space-y-6">
        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">Sender ID</label>
          <div class="relative">
            <select
              v-model="senderId"
              class="w-full appearance-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors focus:border-azure-500/50 focus:bg-white/[0.05]"
            >
              <option value="" disabled>Select sender ID...</option>
              <option v-for="s in state.senderIds" :key="s.name" :value="s.name">{{ s.name }}</option>
            </select>
            <AppIcon
              name="chevron-down"
              class="pointer-events-none absolute right-4 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500"
            />
          </div>
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">Recipients</label>
          <div class="mb-3 grid grid-cols-2 gap-1 rounded-xl border border-white/[0.08] bg-white/[0.02] p-1">
            <button
              type="button"
              class="rounded-lg py-2 text-sm font-semibold transition-colors"
              :class="
                mode === 'manual'
                  ? 'bg-gradient-to-br from-azure-500 to-azure-600 text-white shadow-[0_2px_10px_-2px_rgba(28,120,245,0.6)]'
                  : 'text-zinc-400 hover:text-zinc-200'
              "
              @click="mode = 'manual'"
            >
              Manual
            </button>
            <button
              type="button"
              class="rounded-lg py-2 text-sm font-semibold transition-colors"
              :class="
                mode === 'list'
                  ? 'bg-gradient-to-br from-azure-500 to-azure-600 text-white shadow-[0_2px_10px_-2px_rgba(28,120,245,0.6)]'
                  : 'text-zinc-400 hover:text-zinc-200'
              "
              @click="mode = 'list'"
            >
              Contact List
            </button>
          </div>

          <textarea
            v-if="mode === 'manual'"
            v-model="recipients"
            rows="3"
            placeholder="255712345678, 255787654321"
            class="w-full resize-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 font-mono text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          ></textarea>
          <select
            v-else
            class="w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none focus:border-azure-500/50"
          >
            <option v-if="!state.contactLists.length" disabled selected>No contact lists yet</option>
            <option v-for="c in state.contactLists" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
          <p class="mt-2 text-xs text-zinc-500">
            Tanzanian numbers — separate multiple with commas or newlines
            <span v-if="recipientCount"> · {{ recipientCount }} recipient{{ recipientCount > 1 ? 's' : '' }}</span>
          </p>
        </div>

        <div>
          <label class="mb-2 block text-sm font-medium text-zinc-300">Message</label>
          <textarea
            v-model="message"
            rows="5"
            placeholder="Type your message here..."
            class="w-full resize-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]"
          ></textarea>
          <p class="mt-2 tabular font-mono text-xs text-zinc-500">
            {{ message.length }} characters · {{ segments }} segment{{ segments > 1 ? 's' : '' }}
          </p>
        </div>

        <button
          type="button"
          :disabled="!canSend"
          class="flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
          @click="handleSend"
        >
          <AppIcon name="send" class="h-4 w-4" />
          Send Message
        </button>
      </div>
    </Panel>
  </div>
</template>
