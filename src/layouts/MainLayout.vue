<script setup>
import { RouterView } from 'vue-router'
import Navbar from '../components/Navbar.vue'
</script>

<template>
  <div class="app-layout">
    <Navbar />
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.app-layout {
  min-height: 100vh;
  background-color: #f4f6f8;
  font-family:
    -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans',
    'Helvetica Neue', sans-serif;
}
.main-content {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}
</style>
