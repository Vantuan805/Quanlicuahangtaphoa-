// API Client Wrapper for Grocery Store Management
const api = {
  async get(endpoint) {
    try {
      const res = await fetch(endpoint);
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || `HTTP ${res.status}`);
      }
      return json;
    } catch (err) {
      console.error(`GET ${endpoint} failed:`, err);
      throw err;
    }
  },

  async post(endpoint, data) {
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || `HTTP ${res.status}`);
      }
      return json;
    } catch (err) {
      console.error(`POST ${endpoint} failed:`, err);
      throw err;
    }
  },

  async put(endpoint, data) {
    try {
      const res = await fetch(endpoint, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || `HTTP ${res.status}`);
      }
      return json;
    } catch (err) {
      console.error(`PUT ${endpoint} failed:`, err);
      throw err;
    }
  },

  async delete(endpoint) {
    try {
      const res = await fetch(endpoint, { method: 'DELETE' });
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || `HTTP ${res.status}`);
      }
      return json;
    } catch (err) {
      console.error(`DELETE ${endpoint} failed:`, err);
      throw err;
    }
  }
};
