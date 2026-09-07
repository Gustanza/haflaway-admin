<script setup>
import { ref } from 'vue'
import Panel from '../components/ui/Panel.vue'
import Badge from '../components/ui/Badge.vue'
import { useStore } from '../store/useStore'
import { formatDate, truncate } from '../utils/format'

const { state, generateApiKey, revokeApiKey } = useStore()

const revealedSecret = ref(null)

function handleGenerate() {
  const key = generateApiKey()
  revealedSecret.value = key
}
</script>

<template>
  <div class="grid grid-cols-1 gap-5 lg:grid-cols-[380px_1fr]">
    <div class="space-y-5">
      <Panel title="Generate New Key">
        <p class="text-sm text-zinc-500">
          Each key has a public and secret component. The secret is shown only once.
        </p>
        <button
          type="button"
          class="mt-5 w-full rounded-xl bg-gradient-to-br from-azure-500 to-azure-600 py-3 text-sm font-semibold text-white shadow-[0_8px_24px_-8px_rgba(28,120,245,0.6)] transition-transform hover:scale-[1.01] active:scale-[0.99]"
          @click="handleGenerate"
        >
          Generate API Key
        </button>

        <div
          v-if="revealedSecret"
          class="mt-5 space-y-3 rounded-xl border border-azure-500/25 bg-azure-500/[0.06] p-4"
        >
          <p class="text-xs font-semibold uppercase tracking-wider text-azure-300">
            Copy your secret now — it won't be shown again
          </p>
          <div>
            <p class="text-xs text-zinc-500">Public key</p>
            <p class="break-all font-mono text-xs text-zinc-300">{{ revealedSecret.publicKey }}</p>
          </div>
          <div>
            <p class="text-xs text-zinc-500">Secret key</p>
            <p class="break-all font-mono text-xs text-zinc-300">{{ revealedSecret.secretKey }}</p>
          </div>
        </div>
      </Panel>

      <Panel title="Usage">
        <p class="text-sm text-zinc-500">
          Send the public key as
          <code class="rounded bg-white/[0.06] px-1.5 py-0.5 font-mono text-xs text-zinc-300">X-API-PUBLIC-KEY</code>
          and secret as
          <code class="rounded bg-white/[0.06] px-1.5 py-0.5 font-mono text-xs text-zinc-300">X-API-SECRET-KEY</code>
          headers.
        </p>
      </Panel>
    </div>

    <Panel>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-b border-white/[0.06] text-xs uppercase tracking-wider text-zinc-500">
              <th class="pb-3 pr-4 font-medium">Public Key</th>
              <th class="pb-3 pr-4 font-medium">Status</th>
              <th class="pb-3 pr-4 font-medium">Last Used</th>
              <th class="pb-3 font-medium">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="k in state.apiKeys"
              :key="k.publicKey"
              class="border-b border-white/[0.04] last:border-0 hover:bg-white/[0.02]"
            >
              <td class="py-3.5 pr-4 font-mono text-zinc-300">{{ truncate(k.publicKey, 22) }}</td>
              <td class="py-3.5 pr-4"><Badge :status="k.status" /></td>
              <td class="py-3.5 pr-4 tabular text-zinc-500">{{ k.lastUsed ? formatDate(k.lastUsed) : '—' }}</td>
              <td class="py-3.5">
                <button
                  v-if="k.status === 'Active'"
                  type="button"
                  class="text-sm font-medium text-rose-400 hover:text-rose-300"
                  @click="revokeApiKey(k.publicKey)"
                >
                  Revoke
                </button>
                <span v-else class="text-sm text-zinc-600">—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </Panel>
  </div>
</template>
