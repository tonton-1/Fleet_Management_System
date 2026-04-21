<script setup>
import { RouterView } from 'vue-router'
</script>

<template>
  <RouterView />
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Kanit:wght@200;300;400;500;600;700&display=swap');

body, 
button, 
input, 
select, 
textarea, 
.app-layout, 
.navbar, 
.login-container,
h1, h2, h3, h4, h5, h6, p, span, div {
  font-family: 'Kanit', sans-serif !important;
}

code, 
pre, 
.mono, 
.audit-payload {
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace !important;
}
</style>
