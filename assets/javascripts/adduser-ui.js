
//= require zxcvbn

jQuery(document).ready(function () {
	const strength = {
		0: "Worst",
		1: "Bad",
		2: "Weak",
		3: "Good",
		4: "Best"
	};

	function isValidPassword(password) {
		if (!/^[\x20-\x7e]{8,}$/.test(password)) {
			return false;
		}
		const kinds = (/[a-z]/.test(password) ? 1 : 0) +
			(/[A-Z]/.test(password) ? 1 : 0) +
			(/[0-9]/.test(password) ? 1 : 0) +
			(/[^a-zA-Z0-9]/.test(password) ? 1 : 0);
		if (kinds < 3) {
			return false;
		}
		return true;
	}

	function validate() {
		const password = jQuery("#form-adduser input[name='$password']");
		const password_confirm = jQuery("#form-adduser input[name='$password_confirm']");
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

	function checkStrength() {
		const password = jQuery("#form-adduser input[name='$password']");
		const password_val = password.val();
		const meter = password.next("meter");
		const message = meter.next("small");

		const result = zxcvbn(password_val);
		meter.attr({value: result.score});
		if (password_val !== "") {
			message.text("Strength: " + strength[result.score]);
		}
	}

	jQuery("#form-adduser input[name='$password']").keyup(checkStrength);
	jQuery("#form-adduser input[name^='$password']").blur(validate);
});

