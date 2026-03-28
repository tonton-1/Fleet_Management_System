import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import MainLayout from '../layouts/MainLayout.vue'
import DashboardView from '../views/DashboardView.vue'
import VehiclesView from '../views/VehiclesView.vue'
import DriversView from '../views/DriversView.vue'
import TripsView from '../views/TripsView.vue'
import AlertsView from '../views/AlertsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'login',
      component: Login,
    },
    {
      path: '/',
      component: MainLayout,
      meta: { requiresAuth: true }, // Applies to all children
      children: [
        {
          path: 'dashboard',
          name: 'dashboard',
          component: DashboardView,
        },
        {
          path: 'vehicles',
          name: 'vehicles',
          component: VehiclesView,
        },
        {
          path: 'drivers',
          name: 'drivers',
          component: DriversView,
        },
        {
          path: 'trips',
          name: 'trips',
          component: TripsView,
        },
        {
          path: 'alerts',
          name: 'alerts',
          component: AlertsView,
        },
      ],
    },
  ],
})

// Global navigation guard
router.beforeEach((to, from, next) => {
  const loggedIn = localStorage.getItem('accessToken')

  // If the route requires authentication and the user is not logged in
  if (to.meta.requiresAuth && !loggedIn) {
    next('/') // Redirect to the login page
  } else {
    next() // Otherwise, proceed as normal
  }
})

export default router
