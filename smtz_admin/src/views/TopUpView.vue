<script setup>
import { ref, reactive } from 'vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import AppIcon from '../components/AppIcon.vue'
import { useStore } from '../store/useStore'
import { formatDateTime } from '../utils/format'

const { state, submitTopUp } = useStore()

const tab = ref('instant')
const form = reactive({ sms: '', network: '', phone: '' })

function handleSubmit() {
  const sms = Number(form.sms)
  if (!sms || sms <= 0 || !form.network || !form.phone.trim()) return
  submitTopUp({ sms, network: form.network, phone: form.phone })
  form.sms = ''
  form.network = ''
  form.phone = ''
}

const selectClass =
  'w-full appearance-none rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors focus:border-azure-500/50 focus:bg-white/[0.05]'
const inputClass =
  'w-full rounded-xl border border-white/[0.08] bg-white/[0.03] px-4 py-3 text-sm text-zinc-100 outline-none transition-colors placeholder:text-zinc-600 focus:border-azure-500/50 focus:bg-white/[0.05]'
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[1fr_380px]">
    <div>
      <div class="mb-4 inline-flex gap-1 rounded-xl border border-white/[0.08] bg-white/[0.02] p-1">
        <button
          type="button"
          class="rounded-lg px-4 py-2 text-sm font-semibold transition-colors"
          :class="tab === 'instant' ? 'bg-white text-ink-950' : 'text-zinc-400 hover:text-zinc-200'"
          @click="tab = 'instant'"
        >
          Pay Now (Instant)
        </button>
        <button
          type="button"
          class="rounded-lg px-4 py-2 text-sm font-semibold transition-colors"
          :class="tab === 'manual' ? 'bg-white text-ink-950' : 'text-zinc-400 hover:text-zinc-200'"
          @click="tab = 'manual'"
        >
          Pay Manually
        </button>
      </div>

      <Panel v-if="tab === 'instant'">
        <div class="mb-1 flex items-center gap-2.5">
          <h2 class="text-[15px] font-semibold text-zinc-100">Pay Now (Instant)</h2>
          <span
            class="rounded-full bg-emerald-400/10 px-2 py-0.5 text-xs font-medium text-emerald-300 ring-1 ring-inset ring-emerald-400/20"
          >
            Fastest
          </span>
        </div>
        <p class="mb-6 text-sm text-zinc-500">
          Approve a mobile money prompt on your phone — credits automatically, no waiting for admin review.
        </p>

        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Package</label>
            <div class="relative">
              <select :class="selectClass">
                <option>Custom Rate — TZS</option>
              </select>
              <AppIcon
                name="chevron-down"
                class="pointer-events-none absolute right-4 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500"
              />
            </div>
          </div>
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">SMS Quantity</label>
            <input v-model="form.sms" type="number" min="1" placeholder="e.g. 1000" :class="inputClass" />
          </div>
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Mobile Money Network</label>
            <div class="relative">
              <select v-model="form.network" :class="selectClass">
                <option value="" disabled>Select network...</option>
                <option value="M-Pesa">M-Pesa</option>
                <option value="Tigo Pesa">Tigo Pesa</option>
                <option value="Airtel Money">Airtel Money</option>
              </select>
              <AppIcon
                name="chevron-down"
                class="pointer-events-none absolute right-4 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-500"
              />
            </div>
          </div>
          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-300">Phone Number to Pay From</label>
            <input v-model="form.phone" type="text" placeholder="e.g. 0712345678" :class="inputClass" />
          </div>
        </div>

        <button
          type="button"
          :disabled="!form.sms || !form.network || !form.phone.trim()"
          class="mt-6 w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99] disabled:pointer-events-none disabled:opacity-50"
          @click="handleSubmit"
        >
          Send Payment Request
        </button>
      </Panel>

      <Panel v-else title="Pay Manually">
        <p class="text-sm text-zinc-500">
          Make a manual bank or mobile money transfer and submit proof of payment for admin review.
        </p>
      </Panel>
    </div>

    <Panel title="Recent Requests">
      <div class="space-y-1">
        <div
          v-for="r in state.topUpRequests"
          :key="r.id"
          class="flex items-center justify-between border-b border-white/[0.04] py-3 last:border-0"
        >
          <div>
            <p class="tabular font-mono text-sm font-semibold text-zinc-100">{{ r.sms.toLocaleString() }} SMS</p>
            <p class="tabular font-mono text-xs text-zinc-500">TZS {{ r.amountTzs.toLocaleString() }}</p>
          </div>
          <Badge :status="r.status" />
        </div>
      </div>
    </Panel>
  </div>
</template>
