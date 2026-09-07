import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: () => import('../views/DashboardView.vue'),
    meta: { title: 'Dashboard', subtitle: 'Welcome back' },
  },
  {
    path: '/send-sms',
    name: 'send-sms',
    component: () => import('../views/SendSmsView.vue'),
    meta: { title: 'Send SMS', subtitle: 'Send a message to one or more recipients' },
  },
  {
    path: '/messages',
    name: 'messages',
    component: () => import('../views/MessagesView.vue'),
    meta: { title: 'Messages', subtitle: 'Every message sent through your account' },
  },
  {
    path: '/contact-lists',
    name: 'contact-lists',
    component: () => import('../views/ContactListsView.vue'),
    meta: { title: 'Contact Lists', subtitle: 'Manage groups of phone numbers for bulk messaging' },
  },
  {
    path: '/templates',
    name: 'templates',
    component: () => import('../views/TemplatesView.vue'),
    meta: { title: 'Message Templates', subtitle: 'Save reusable message bodies for quick sending' },
  },
  {
    path: '/delivery-reports',
    name: 'delivery-reports',
    component: () => import('../views/DeliveryReportsView.vue'),
    meta: { title: 'Delivery Reports', subtitle: 'Batch delivery summaries' },
  },
  {
    path: '/sender-ids',
    name: 'sender-ids',
    component: () => import('../views/SenderIdsView.vue'),
    meta: { title: 'Sender IDs', subtitle: 'Manage your approved sender identifiers' },
  },
  {
    path: '/api-keys',
    name: 'api-keys',
    component: () => import('../views/ApiKeysView.vue'),
    meta: { title: 'API Keys', subtitle: 'Manage your programmatic access keys' },
  },
  {
    path: '/webhooks',
    name: 'webhooks',
    component: () => import('../views/WebhooksView.vue'),
    meta: { title: 'Webhooks', subtitle: 'Receive delivery notifications at your endpoint' },
  },
  {
    path: '/top-up',
    name: 'top-up',
    component: () => import('../views/TopUpView.vue'),
    meta: { title: 'Top Up', subtitle: 'Add SMS credits to your account' },
  },
  {
    path: '/transactions',
    name: 'transactions',
    component: () => import('../views/TransactionsView.vue'),
    meta: { title: 'Transactions', subtitle: 'Your SMS credit history' },
  },
]

export default createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 }
  },
})
