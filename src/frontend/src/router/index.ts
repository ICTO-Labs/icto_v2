import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to: any, from: any, savedPosition: any) {
    return savedPosition || { left: 0, top: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'Ecommerce',
      component: () => import('../views/Ecommerce.vue'),
      meta: {
        title: 'Dashboard',
      },
    },
    {
      path: '/tokens',
      name: 'Tokens',
      component: () => import('../views/Token/TokenIndex.vue'),
      meta: {
        title: 'Tokens Center',
      },
    },
    {
      path: '/tokens/:id',
      component: () => import('../views/Token/TokenDetail.vue'),
      meta: { 
        title: 'Token Detail',
      }
    },
    {
      path: '/multisig',
      name: 'Multisig',
      component: () => import('../views/Multisig/MultisigIndex.vue'),
      meta: {
        title: 'Multisig Wallets',
      },
    },
    {
      path: '/multisig/:id',
      component: () => import('../views/Multisig/MultisigDetail.vue'),
      meta: { 
        title: 'Multisig Wallet Detail',
      }
    },
    {
      path: '/multisig/:id/proposal/:proposalId',
      component: () => import('../views/Multisig/ProposalDetail.vue'),
      meta: { 
        title: 'Proposal Detail',
      }
    },
    {
      path: '/calendar',
      name: 'Calendar',
      component: () => import('../views/Others/Calendar.vue'),
      meta: {
        title: 'Calendar',
      },
    },
    {
      path: '/profile',
      name: 'Profile',
      component: () => import('../views/User/Index.vue'),
      meta: {
        title: 'Profile',
      },
    },
    {
      path: '/form-elements',
      name: 'Form Elements',
      component: () => import('../views/Forms/FormElements.vue'),
      meta: {
        title: 'Form Elements',
      },
    },
    {
      path: '/basic-tables',
      name: 'Basic Tables',
      component: () => import('../views/Tables/BasicTables.vue'),
      meta: {
        title: 'Basic Tables',
      },
    },
    {
      path: '/line-chart',
      name: 'Line Chart',
      component: () => import('../views/Chart/LineChart/LineChart.vue'),
    },
    {
      path: '/bar-chart',
      name: 'Bar Chart',
      component: () => import('../views/Chart/BarChart/BarChart.vue'),
    },
    {
      path: '/alerts',
      name: 'Alerts',
      component: () => import('../views/UiElements/Alerts.vue'),
      meta: {
        title: 'Alerts',
      },
    },
    {
      path: '/avatars',
      name: 'Avatars',
      component: () => import('../views/UiElements/Avatars.vue'),
      meta: {
        title: 'Avatars',
      },
    },
    {
      path: '/badge',
      name: 'Badge',
      component: () => import('../views/UiElements/Badges.vue'),
      meta: {
        title: 'Badge',
      },
    },

    {
      path: '/buttons',
      name: 'Buttons',
      component: () => import('../views/UiElements/Buttons.vue'),
      meta: {
        title: 'Buttons',
      },
    },

    {
      path: '/images',
      name: 'Images',
      component: () => import('../views/UiElements/Images.vue'),
      meta: {
        title: 'Images',
      },
    },
    {
      path: '/videos',
      name: 'Videos',
      component: () => import('../views/UiElements/Videos.vue'),
      meta: {
        title: 'Videos',
      },
    },
    {
      path: '/blank',
      name: 'Blank',
      component: () => import('../views/Pages/BlankPage.vue'),
      meta: {
        title: 'Blank',
      },
    },

    {
      path: '/error-404',
      name: '404 Error',
      component: () => import('../views/Errors/FourZeroFour.vue'),
      meta: {
        title: '404 Error',
      },
    },

    {
      path: '/signin',
      name: 'Signin',
      component: () => import('../views/Auth/Signin.vue'),
      meta: {
        title: 'Signin',
      },
    },
    {
      path: '/signup',
      name: 'Signup',
      component: () => import('../views/Auth/Signup.vue'),
      meta: {
        title: 'Signup',
      },
    },
    {
      path: '/user',
      name: 'user-center',
      component: () => import('@/views/User/Index.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/user/:id',
      component: () => import('@/views/Dashboard/User.vue'),
      meta: { requiresAuth: true }
    },
  
    {
      path: '/distribution',
      name: 'Distribution',
      component: () => import('../views/Distribution/DistributionIndex.vue'),
      meta: {
        title: 'Distribution Center',
      },
    },
    {
      path: '/distribution/create',
      name: 'DistributionCreate',
      component: () => import('../views/Distribution/DistributionCreate.vue'),
      meta: {
        title: 'Create Distribution',
      },
    },
    {
      path: '/distribution/:id',
      name: 'DistributionDetail',
      component: () => import('../views/Distribution/DistributionDetail.vue'),
      meta: {
        title: 'Distribution Detail',
      },
    },
    {
      path: '/launchpad',
      name: 'LaunchpadIndex',
      component: () => import('@/views/Launchpad/LaunchpadIndex.vue'),
    },
    {
      path: '/launchpad/:id',
      name: 'LaunchpadDetail',
      component: () => import('@/views/Launchpad/LaunchpadDetail.vue'),
    },
  ],
})

export default router
router.beforeEach((to: any, from: any, next: any) => {
  document.title = `${to.meta.title} | ICTO`
  next()
})

