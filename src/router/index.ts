import { ref } from 'vue'

export type RouteNames =
  | 'home'
  | 'pros-locaux'
  | 'about'
  | 'contact'
  | 'blog'
  | 'blog-post'
  | 'company-detail'
  | 'login'
  | 'dashboard'
  | 'dashboard-profile'
  | 'dashboard-products'
  | 'dashboard-quotes'
  | 'dashboard-visibility'
  | 'dashboard-payments'
  | 'admin'
  | 'admin-companies'
  | 'admin-quotes'
  | 'admin-payments'
  | 'admin-blog'

export interface Route {
  name: RouteNames
  params?: Record<string, string>
}

export const currentRoute = ref<Route>({ name: 'home' })

export function navigateTo(route: Route) {
  currentRoute.value = route
  window.scrollTo(0, 0)
}

export function useRoute() {
  return currentRoute
}

export function isAuthRoute(routeName: RouteNames): boolean {
  return routeName.startsWith('dashboard') || routeName.startsWith('admin')
}

export function isDashboardRoute(routeName: RouteNames): boolean {
  return routeName.startsWith('dashboard')
}

export function isAdminRoute(routeName: RouteNames): boolean {
  return routeName.startsWith('admin')
}
