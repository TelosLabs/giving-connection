export const useCookies = controller => {
  Object.assign(controller, {
    getCookie(key) {
      const cookieValue = document.cookie.split('; ').find(row => row.startsWith(`${key}=`))?.split('=')[1];
      return cookieValue || null;
    },

    setCookie(key, value) {
      document.cookie = `${key}=${value};path=/`;
    }
  })
}
