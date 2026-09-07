<script setup>
defineProps({
  name: { type: String, required: true },
})

const icons = {
  home: '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9a1 1 0 0 0 1 1h3v-5h4v5h3a1 1 0 0 0 1-1v-9"/>',
  send: '<path d="M21 3 3 10.5l7.5 2.8L13.4 21 21 3Z"/><path d="M10.5 13.3 21 3"/>',
  chat: '<path d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 4V6Z"/>',
  users: '<circle cx="8.5" cy="8" r="3"/><path d="M2.5 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><circle cx="17" cy="9.5" r="2.3"/><path d="M15.2 20c.3-2.6 2-4.7 4.3-5.3"/>',
  document: '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/>',
  chart: '<path d="M4 20V10M11 20V4M18 20v-7"/><path d="M3 20h18"/>',
  badge: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><circle cx="9" cy="12" r="2"/><path d="M14 10h4M14 14h4"/>',
  key: '<circle cx="7.5" cy="7.5" r="4.2"/><path d="M10.6 10.6 21 21M15.5 15.5l2.3-2.3M18.3 18.3l2.3-2.3"/>',
  dollar: '<path d="M12 4v16M8.5 8c0-1.8 1.6-3 3.5-3s3.5 1.1 3.5 2.7c0 3.4-7 2-7 5.3 0 1.6 1.6 2.7 3.5 2.7s3.5-1.2 3.5-3"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.2 3.2"/>',
  'chevron-down': '<path d="M6 9l6 6 6-6"/>',
  'chevron-right': '<path d="M9 6l6 6-6 6"/>',
  'arrow-up-right': '<path d="M7 17 17 7M9 7h8v8"/>',
  logout: '<path d="M9 21H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h3"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  'x-circle': '<circle cx="12" cy="12" r="9"/><path d="M9 9l6 6M15 9l-6 6"/>',
  download: '<path d="M12 3v12M7 10l5 5 5-5"/><path d="M5 21h14"/>',
  inbox: '<path d="M3 12h5l1.5 3h5L16 12h5"/><path d="M5.5 6h13L21 12v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-6L5.5 6Z"/>',
  link: '<path d="M10.5 13.5a3.5 3.5 0 0 0 5 .3l2-2a3.5 3.5 0 0 0-5-5l-1.1 1"/><path d="M13.5 10.5a3.5 3.5 0 0 0-5-.3l-2 2a3.5 3.5 0 0 0 5 5l1.1-1"/>',
  receipt: '<path d="M6 3h12v18l-2.5-1.5L13 21l-2.5-1.5L8 21l-2-1.5V3Z"/><path d="M9 8h6M9 12h6"/>',
}
</script>

<template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.6"
    stroke-linecap="round"
    stroke-linejoin="round"
    v-html="icons[name] ?? ''"
  ></svg>
</template>
