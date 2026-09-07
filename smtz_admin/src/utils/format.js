export function formatDateTime(date) {
  if (!date) return '—'
  const d = new Date(date)
  const pad = (n) => String(n).padStart(2, '0')
  return `${pad(d.getDate())}-${pad(d.getMonth() + 1)}-${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function formatDate(date) {
  if (!date) return '—'
  const d = new Date(date)
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  return `${pad2(d.getDate())} ${months[d.getMonth()]} ${d.getFullYear()}`
}

function pad2(n) {
  return String(n).padStart(2, '0')
}

export function truncate(str, len = 28) {
  if (!str) return ''
  return str.length > len ? str.slice(0, len) + '…' : str
}
