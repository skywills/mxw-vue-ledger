<template>
  <div id="app">
    <h1>MXW </h1>
    <MxwLedger msg="Minimal MXW+Ledger delegation example" />
  </div>
</template>

<script>
import MxwLedger from './components/MxwLedger';
import './assets/bootstrap-3.3.7/css/bootstrap.min.css';

export default {
    name: 'App',
    components: {
        MxwLedger,
    },
};
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
