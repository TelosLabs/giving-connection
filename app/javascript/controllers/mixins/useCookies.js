export const useCookies = controller => {
  Object.assign(controller, {
    getCookie(key) {
      return document.cookie.split('; ').find(row => row.startsWith(`${key}=`))?.split('=')[1] || null;
    },

    setCookie(key, value) {
      document.cookie = `${key}=${value};path=/`;
    }
  })
}
