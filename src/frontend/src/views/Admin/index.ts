// Export admin components
export { default as AdminDashboard } from './AdminDashboard.vue'

// Admin route configuration
export const adminRoutes = [
  {
    path: '/admin',
    name: 'admin',
    redirect: '/admin/dashboard'
  },
  {
    path: '/admin/dashboard',
    name: 'admin-dashboard',
    component: () => import('./AdminDashboard.vue'),
    meta: {
      title: 'Admin Dashboard',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/users',
    name: 'admin-users',
    component: () => import('./AdminUsers.vue'),
    meta: {
      title: 'User Management',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/users/:id',
    name: 'admin-user-detail',
    component: () => import('./AdminUserDetail.vue'),
    meta: {
      title: 'User Details',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/payments',
    name: 'admin-payments',
    component: () => import('./AdminPayments.vue'),
    meta: {
      title: 'Payment Management',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/refunds',
    name: 'admin-refunds',
    component: () => import('./AdminRefunds.vue'),
    meta: {
      title: 'Refund Management',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/deployments',
    name: 'admin-deployments',
    component: () => import('./AdminDeployments.vue'),
    meta: {
      title: 'Deployment Management',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/audit',
    name: 'admin-audit',
    component: () => import('./AdminAudit.vue'),
    meta: {
      title: 'Audit Logs',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/config',
    name: 'admin-config',
    component: () => import('./AdminConfig.vue'),
    meta: {
      title: 'System Configuration',
      requiresAuth: true,
      requiresAdmin: true
    }
  },
  {
    path: '/admin/health',
    name: 'admin-health',
    component: () => import('./AdminHealth.vue'),
    meta: {
      title: 'System Health',
      requiresAuth: true,
      requiresAdmin: true
    }
  }
]