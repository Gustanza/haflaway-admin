<script setup>
defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
})
</script>

<template>
  <div
    class="rounded-2xl border border-white/[0.08] bg-white/[0.03] backdrop-blur-sm shadow-[0_1px_0_rgba(255,255,255,0.04)_inset] transition-colors hover:border-white/[0.12]"
  >
    <div v-if="title" class="border-b border-white/[0.06] px-6 py-5">
      <h2 class="text-[15px] font-semibold text-zinc-100">{{ title }}</h2>
      <p v-if="subtitle" class="mt-0.5 text-sm text-zinc-500">{{ subtitle }}</p>
    </div>
    <div class="p-6">
      <slot />
    </div>
  </div>
</template>
