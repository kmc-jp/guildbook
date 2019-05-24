import * as jQuery from 'jquery';
import 'bootstrap';
import '../src/app.scss';

jQuery(document).ready(function($) {
  const pubkeyPattern = /^(?:ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519) /;

  function validateSshPublicKey() {
    for (const [i, pubkey] of this.value.trim().split(/\r?\n/).entries()) {
      if(!pubkeyPattern.test(pubkey)) {
        this.setCustomValidity(`${i+1}行目の公開鍵がおかしいです`);
        return;
      }
    }
    this.setCustomValidity('');
  }

  $('textarea.ssh-public-key').on('input', validateSshPublicKey);
});
