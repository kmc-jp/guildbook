import * as jQuery from 'jquery';
import 'bootstrap';
import '../src/app.scss';

document.addEventListener('DOMContentLoaded', e => {
  document.querySelectorAll<HTMLFormElement>('form.needs-validation').forEach(form => {
    type Control = HTMLInputElement | HTMLTextAreaElement;
    const validatingControls = form.querySelectorAll<Control>('.form-control:not(.no-validation)');

    function setValidator(control: Control, fn: (e: Event) => any, events: string[] = ['input', 'keyup', 'blur']) {
      events.forEach(event =>  control.addEventListener(event, fn))
    }

    form.addEventListener('submit', e => {
      if(!form.reportValidity()) {
        e.preventDefault();
        e.stopPropagation();
      }
    });

    validatingControls.forEach(control => {
      const feedback = document.createElement('div');
      feedback.classList.add('invalid-feedback');

      setValidator(control, e => {
        if(control.checkValidity()) {
          if(feedback.isConnected) {
            control.parentElement.removeChild(feedback);
          }
        } else {
          feedback.textContent = control.validationMessage;
          control.parentElement.insertBefore(feedback, control.nextSibling);
        }
        control.parentElement.classList.add('was-validated');
      });
    });

    // Custom validations
    const pubkeyPattern = /^(?:ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519) /;
    form.querySelectorAll<HTMLTextAreaElement>('textarea.form-control.ssh-public-key').forEach(textarea => {
      setValidator(textarea, e => {
        for(const [i, pubkey] of textarea.value.trim().split(/\r?\n/).entries()) {
          if(pubkey !== '' && !pubkeyPattern.test(pubkey)) {
            textarea.setCustomValidity(`${i+1}行目の公開鍵がおかしいです`);
            return;
          }
        }
        textarea.setCustomValidity('');
      });
    });

    form.querySelectorAll<HTMLInputElement>('input.form-control.password').forEach(async input => {
      const {default: zxcvbn} = await import('zxcvbn') as any;  // XXX: why is this not typeable?

      const userInputs = input.form.querySelectorAll<HTMLInputElement>('input.password-userinput');
      const strengthMeter = document.querySelector<HTMLMeterElement>(input.dataset.passwordStrengthMeter);

      setValidator(input, e => {
        const password = input.value;

        if(/[^\x20-\x7e]/.test(password)) {
          input.setCustomValidity('パスワードにはASCII範囲の印字可能文字のみ使ってください');
          strengthMeter.value = 0;
          return;
        }

        const dictionary = [...userInputs].map(input => input.value);
        const strength = zxcvbn(password, dictionary);
        strengthMeter.value = strength.score;

        if(password.length < 8) {
          input.setCustomValidity('パスワードは8文字以上必要です');
          return;
        }

        const kinds = (/[a-z]/.test(password) ? 1 : 0) +
          (/[A-Z]/.test(password) ? 1 : 0) +
          (/[0-9]/.test(password) ? 1 : 0) +
          (/[^a-zA-Z0-9]/.test(password) ? 1 : 0);
        if(kinds < 3) {
          input.setCustomValidity('大文字・小文字・数字・記号のうち3種類以上を使ってください');
          return;
        }

        if(strength.score <= 2) {
          if(strength.feedback.warning !== '') {
            input.setCustomValidity(strength.feedback.warning);
          } else {
            input.setCustomValidity('もうすこし強そうなパスワードにしてください');
          }
          return;
        }

        input.setCustomValidity('');
      });
    });

    form.querySelectorAll<HTMLInputElement>('input.form-control.password-confirm').forEach(confirmInput => {
      const passwordInput = document.querySelector<HTMLInputElement>(confirmInput.dataset.passwordConfirmFor);

      const validate = e => {
        if(confirmInput.value !== passwordInput.value) {
          confirmInput.setCustomValidity('パスワードが一致しません');
          return;
        }
        confirmInput.setCustomValidity('');
      };

      setValidator(confirmInput, validate);
      setValidator(passwordInput, validate);
    });

    form.querySelectorAll<HTMLInputElement>('input.form-control.remote-validation').forEach(input => {
      const action = input.dataset.remoteValidationAction;

      let previous_value: string | null = null;
      setValidator(input, e => {
        const value = input.value;

        if(value !== '') {
          if(value === previous_value) return;
          previous_value = value;

          const formdata = new FormData();
          formdata.append('value', value);

          fetch(action, {
            method: 'POST',
            mode: 'same-origin',
            credentials: 'same-origin',
            body: formdata,
          }).then(response => response.json()).then(response => {
            if(response.value === input.value) {
              if(response.ok) {
                input.setCustomValidity('');
              } else {
                input.setCustomValidity(response.message);
              }
            }
          });

          return;
        }

        input.setCustomValidity('');
      });
    });
  });

  document.querySelectorAll<HTMLFormElement>('form.needs-confirmation').forEach(form => {
    form.addEventListener('submit', e => {
      if(confirm('入力内容が正しいことを確認しましたか？') && confirm('本当に確認しましたか？')) {
        // default
      } else {
        e.preventDefault();
        e.stopPropagation();
      }
    });
  });
});
