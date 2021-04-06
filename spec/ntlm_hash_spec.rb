require 'ntlm_hash'

ntlm_examples = {
  '' => '31D6CFE0D16AE931B73C59D7E0C089C0',
  'password' => '8846F7EAEE8FB117AD06BDD830B7586C',
  'combatechizen' => '127B47D9BF171845CA1B6DE651B3F494',

  'reuE6iiMc/5oEoZn' => '28000798788C57F48A8C1E01ED40437C',
  '40oBGBbPhA3VLBTJ' => '57DC6C82566D1295C75D1CE95C45AFF8',
  'XRbPjpJ5V7AhGuf0' => '4570DBF9958EC1891FC900B03E1CDCA0',
  'PLmhtdS/GoQuULjd' => '86512D5CA449562668A74A16E3DE9419',
}

RSpec.describe NtlmHash do
  describe '.ntlm_hash' do
    ntlm_examples.each do |plain, hash|
      example "ntlm_hash(#{plain})" do
        expect(NtlmHash.ntlm_hash(plain)).to eq hash
      end
    end
  end
end
