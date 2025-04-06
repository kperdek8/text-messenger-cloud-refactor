const Hooks = {};

// Define your SubmitLogoutForm hook
Hooks.SubmitLogoutForm = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      document.getElementById("logout-form").submit();
    });
  },
};

Hooks.SubmitLoginForm = {
  mounted() {
    this.handleEvent("trigger_login_post", ({access_token, id_token}) => {
      const hiddenForm = document.getElementById("hidden-login-form");
      const accessTokenInput = document.getElementById("access-token-input");
      const idTokenInput = document.getElementById("id-token-input");

      accessTokenInput.value = access_token;
      idTokenInput.value = id_token;
      hiddenForm.submit();
    });
  },
};

Hooks.CopyUUID = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      const text = this.el.innerText.replace("UUID: ", ""); // Extract the UUID part
      navigator.clipboard.writeText(text).then(function () {
        alert("UUID copied to clipboard!");
      }).catch(function (err) {
        alert("Failed to copy UUID: ", err);
      });
    });
  }
}

// Export the Hooks object
export default Hooks;
