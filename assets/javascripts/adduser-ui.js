
//= require zxcvbn

jQuery(document).ready(function () {
	const kmcDictionary = ["kmc"];

	const strength = {
		0: "ぽよい",
		1: "弱い",
		2: "普通",
		3: "強い",
		4: "めちゃっょぃ"
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
		const message = password.siblings("small");
		jQuery("#form-adduser input").parent().removeClass("has-error");
		jQuery("#form-adduser input[type='submit']").attr({disabled: false});
		if (!isValidPassword(password.val())) {
			password.parent().addClass("has-error");
			message.text("8文字以上で大文字・小文字・数字・記号から3種類以上必要です");
		}
		if (password.val() !== password_confirm.val()) {
			password_confirm.parent().addClass("has-error");
			message.text("パスワードが一致しません");
		}
		if (jQuery("#form-adduser input").parent().hasClass("has-error")) {
			jQuery("#form-adduser input[type='submit']").attr({disabled: true});
		} else {
			checkStrength();
		}
	}

	function getUserDictionaryFromForm() {
		const form = jQuery("#form-adduser");
		return kmcDictionary.concat(
			form.find("input[name='$uid']").val(),
			form.find("input[name='$surname']").val(),
			form.find("input[name='$givenname']").val()
		);
	}

	function checkStrength() {
		const password = jQuery("#form-adduser input[name='$password']");
		const password_val = password.val();
		const meter = password.next("meter");
		const message = meter.next("small");

		const result = zxcvbn(password_val, getUserDictionaryFromForm());
		meter.attr({value: result.score});
		if (password_val !== "") {
			message.text("強度：" + strength[result.score]);
		}
	}

	jQuery("#form-adduser input[name='$password']").keyup(checkStrength);
	jQuery("#form-adduser input[name^='$password']").blur(validate);
});

