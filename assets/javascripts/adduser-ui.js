
jQuery(document).ready(function () {
	function isValidPassword(password) {
		if (!/^[\x20-\x7e]{8,}$/.test(password)) {
			return false;
		}
		let kinds = (/[a-z]/.test(password) ? 1 : 0) +
			(/[A-Z]/.test(password) ? 1 : 0) +
			(/[0-9]/.test(password) ? 1 : 0) +
			(/[^a-zA-Z0-9]/.test(password) ? 1 : 0);
		if (kinds < 3) {
			return false;
		}
		return true;
	}

	function validate() {
		let password = jQuery("#form-adduser input[name='$password']");
		let password_confirm = jQuery("#form-adduser input[name='$password_confirm']");
		jQuery("#form-adduser input").parent().removeClass("has-error");
		jQuery("#form-adduser input[type='submit']").attr({disabled: false});
		if (!isValidPassword(password.val())) {
			password.parent().addClass("has-error");
		}
		if (password.val() !== password_confirm.val()) {
			password_confirm.parent().addClass("has-error");
		}
		if (jQuery("#form-adduser input").parent().hasClass("has-error")) {
			jQuery("#form-adduser input[type='submit']").attr({disabled: true});
		}
	}

	jQuery("#form-adduser input[name^='$password']").blur(validate);
});

