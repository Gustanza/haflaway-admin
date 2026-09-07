import { reactive } from 'vue'

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

const names = [
  'DUNIA RAJABU',
  'MABULA KISASU',
  'JOHN KASHINDYE',
  'DIONIZ MUDO',
  'SOPHIA NKWABI',
  'JASMIN NKWABI',
  'DAUD LUGENJI',
]

function seedMessages() {
  const now = new Date('2026-08-04T13:51:00')
  return names.map((name, i) => {
    const sentAt = new Date(now.getTime() - i * 1000 * 60 * (i < 4 ? 0 : 232))
    return {
      id: uuid(),
      recipient: `+2557${Math.floor(10000000 + Math.random() * 89999999)}`,
      senderId: 'HAFLAWAY',
      message: `Habari ${name} Tunayofuraha kukujulisha...`,
      seg: 2,
      status: 'Delivered',
      sentAt,
      deliveredAt: sentAt,
    }
  })
}

const state = reactive({
  user: {
    name: 'GODWILL STANLEY SAM',
    email: 'haflaway@gmail.com',
  },
  account: {
    balanceSms: 3076,
    totalMessages: 36600,
    sentToday: 10,
    pendingTopUps: 0,
  },
  messages: seedMessages(),
  contactLists: [],
  templates: [],
  deliveryReports: seedMessages().map((m) => ({
    id: uuid(),
    delivered: 1,
    failed: 0,
    total: 1,
    date: m.sentAt,
  })),
  senderIds: [
    { name: 'HAFLAWAY', sample: 'Hawayuu', status: 'Approved', requested: new Date('2026-05-08') },
    { name: 'ECARDTZ', sample: '—', status: 'Approved', requested: new Date('2026-07-27') },
    { name: 'WASAMBAZIE', sample: '—', status: 'Approved', requested: new Date('2026-07-27') },
  ],
  apiKeys: [
    {
      publicKey: 'pk__d-H9yWJvInRJ3rwPsK0saS7fQz2m',
      secretKey: null,
      status: 'Active',
      lastUsed: new Date('2026-08-04'),
    },
  ],
  webhooks: [
    {
      id: uuid(),
      url: 'https://reportwasambazie-frbu33fema-uc.a.run.app/hooks/delivery',
      status: 'Active',
      createdAt: new Date('2026-07-20'),
    },
  ],
  topUpRequests: [
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Confirmed', date: new Date('2026-08-04T13:00') },
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Confirmed', date: new Date('2026-08-03T10:20') },
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Confirmed', date: new Date('2026-08-02T09:05') },
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Confirmed', date: new Date('2026-08-01T09:00') },
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Confirmed', date: new Date('2026-07-30T14:40') },
    { id: uuid(), sms: 3333, amountTzs: 49995.0, status: 'Processing', date: new Date('2026-07-29T11:15') },
    { id: uuid(), sms: 3333, amountTzs: 46662.0, status: 'Confirmed', date: new Date('2026-07-28T08:30') },
  ],
  transactions: [],
})

state.transactions = state.messages.map((m) => ({
  id: uuid(),
  type: 'Debit',
  amount: -m.seg,
  reference: `SMS Send: ${m.id}`,
  date: m.sentAt,
}))

export function useStore() {
  function sendSms({ senderId, recipients, message }) {
    const now = new Date()
    const list = recipients
      .split(/[,\n]/)
      .map((r) => r.trim())
      .filter(Boolean)

    list.forEach((recipient) => {
      state.messages.unshift({
        id: uuid(),
        recipient,
        senderId: senderId || 'HAFLAWAY',
        message,
        seg: Math.max(1, Math.ceil(message.length / 160)),
        status: 'Delivered',
        sentAt: now,
        deliveredAt: now,
      })
    })

    state.account.sentToday += list.length
    state.account.totalMessages += list.length
    state.account.balanceSms = Math.max(0, state.account.balanceSms - list.length)

    return list.length
  }

  function createContactList({ name, description }) {
    state.contactLists.unshift({
      id: uuid(),
      name,
      description,
      contacts: 0,
      createdAt: new Date(),
    })
  }

  function saveTemplate({ name, body }) {
    state.templates.unshift({
      id: uuid(),
      name,
      body,
      createdAt: new Date(),
    })
  }

  function requestSenderId({ name, sample }) {
    state.senderIds.unshift({
      name: name.toUpperCase(),
      sample: sample || '—',
      status: 'Pending',
      requested: new Date(),
    })
  }

  function generateApiKey() {
    const key = {
      publicKey: 'pk_' + uuid().replace(/-/g, '').slice(0, 27),
      secretKey: 'sk_' + uuid().replace(/-/g, '') + uuid().replace(/-/g, ''),
      status: 'Active',
      lastUsed: null,
    }
    state.apiKeys.unshift(key)
    return key
  }

  function revokeApiKey(publicKey) {
    const key = state.apiKeys.find((k) => k.publicKey === publicKey)
    if (key) key.status = 'Revoked'
  }

  function registerWebhook(url) {
    state.webhooks.unshift({
      id: uuid(),
      url,
      status: 'Active',
      createdAt: new Date(),
    })
  }

  function toggleWebhook(id) {
    const hook = state.webhooks.find((w) => w.id === id)
    if (hook) hook.status = hook.status === 'Active' ? 'Disabled' : 'Active'
  }

  function deleteWebhook(id) {
    state.webhooks = state.webhooks.filter((w) => w.id !== id)
  }

  function submitTopUp({ sms, phone, network }) {
    const amountTzs = Number((sms * 15).toFixed(1))
    state.topUpRequests.unshift({
      id: uuid(),
      sms,
      amountTzs,
      status: 'Processing',
      date: new Date(),
      phone,
      network,
    })
    state.account.pendingTopUps += 1
  }

  return {
    state,
    sendSms,
    createContactList,
    saveTemplate,
    requestSenderId,
    generateApiKey,
    revokeApiKey,
    registerWebhook,
    toggleWebhook,
    deleteWebhook,
    submitTopUp,
  }
}
