import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { startTokenExpirationWatcher } from './utils/tokenExpiration'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')

if (localStorage.getItem('accessToken')) {
  startTokenExpirationWatcher()
}
