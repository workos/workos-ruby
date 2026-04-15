# frozen_string_literal: true

require "test_helper"

class TestMFA < WorkOS::TestCase
  def test_enroll_factor_generic_valid
    VCR.use_cassette "mfa/enroll_factor_generic_valid" do
      factor = WorkOS::MFA.enroll_factor(
        type: "generic_otp"
      )
      assert_equal "generic_otp", factor.type
    end
  end

  def test_enroll_factor_totp_valid
    VCR.use_cassette "mfa/enroll_factor_totp_valid" do
      factor = WorkOS::MFA.enroll_factor(
        type: "totp",
        totp_issuer: "WorkOS",
        totp_user: "some_user"
      )
      assert_kind_of Hash, factor.totp
    end
  end

  def test_enroll_factor_sms_valid
    VCR.use_cassette "mfa/enroll_factor_sms_valid" do
      factor = WorkOS::MFA.enroll_factor(
        type: "sms",
        phone_number: "55555555555"
      )
      assert_kind_of Hash, factor.sms
    end
  end

  def test_enroll_factor_with_invalid_type_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.enroll_factor(
        type: "invalid",
        phone_number: "+15005550006"
      )
    end
    assert_equal "Type argument must be either 'sms' or 'totp'", err.message
  end

  def test_enroll_factor_totp_missing_arguments_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.enroll_factor(
        type: "totp",
        totp_issuer: "WorkOS"
      )
    end
    assert_equal "Incomplete arguments. Need to specify both totp_issuer and totp_user when type is totp", err.message
  end

  def test_enroll_factor_sms_missing_phone_number_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.enroll_factor(
        type: "sms"
      )
    end
    assert_equal "Incomplete arguments. Need to specify phone_number when type is sms", err.message
  end

  def test_challenge_factor_totp
    VCR.use_cassette "mfa/challenge_factor_totp_valid" do
      challenge_factor = WorkOS::MFA.challenge_factor(
        authentication_factor_id: "auth_factor_01FZ4TS0MWPZR7GATS7KCXANQZ"
      )
      assert_kind_of String, challenge_factor.authentication_factor_id
    end
  end

  def test_challenge_factor_sms
    VCR.use_cassette "mfa/challenge_factor_sms_valid" do
      challenge_factor = WorkOS::MFA.challenge_factor(
        authentication_factor_id: "auth_factor_01FZ4TS14D1PHFNZ9GF6YD8M1F",
        sms_template: "Your code is {{code}}"
      )
      assert_kind_of String, challenge_factor.authentication_factor_id
    end
  end

  def test_challenge_factor_generic
    VCR.use_cassette "mfa/challenge_factor_generic_valid" do
      challenge_factor = WorkOS::MFA.challenge_factor(
        authentication_factor_id: "auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M"
      )
      assert_kind_of String, challenge_factor.code
    end
  end

  def test_challenge_factor_missing_authentication_factor_id_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.challenge_factor
    end
    assert_equal "Incomplete arguments: 'authentication_factor_id' is a required argument", err.message
  end

  def test_verify_factor_throws_deprecation_warning
    VCR.use_cassette "mfa/verify_challenge_generic_valid" do
      _, err = capture_io do
        WorkOS::MFA.verify_factor(
          authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
          code: "897792"
        )
      end
      assert_match(/\[DEPRECATION\] `verify_factor` is deprecated. Please use `verify_challenge` instead./, err)
    end
  end

  def test_verify_factor_calls_verify_challenge
    VCR.use_cassette "mfa/verify_challenge_generic_valid" do
      verify_factor = WorkOS::MFA.verify_factor(
        authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
        code: "897792"
      )
      assert_equal true, verify_factor.valid
    end
  end

  def test_verify_challenge_generic_valid_returns_true
    VCR.use_cassette "mfa/verify_challenge_generic_valid" do
      verify_challenge = WorkOS::MFA.verify_challenge(
        authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
        code: "897792"
      )
      assert_equal true, verify_challenge.valid
    end
  end

  def test_verify_challenge_generic_valid_returns_false
    VCR.use_cassette "mfa/verify_challenge_generic_valid_is_false" do
      verify_challenge = WorkOS::MFA.verify_challenge(
        authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
        code: "897792"
      )
      assert_equal false, verify_challenge.valid
    end
  end

  def test_verify_challenge_already_verified_raises_error
    VCR.use_cassette "mfa/verify_challenge_generic_invalid" do
      assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::MFA.verify_challenge(
          authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
          code: "897792"
        )
      end
    end
  end

  def test_verify_challenge_expired_raises_error
    VCR.use_cassette "mfa/verify_challenge_generic_expired" do
      assert_raises(WorkOS::UnprocessableEntityError) do
        WorkOS::MFA.verify_challenge(
          authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J",
          code: "897792"
        )
      end
    end
  end

  def test_verify_challenge_missing_code_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.verify_challenge(
        authentication_challenge_id: "auth_challenge_01FZ4YVRBMXP5ZM0A7BP4AJ12J"
      )
    end
    assert_equal "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments", err.message
  end

  def test_verify_challenge_missing_authentication_challenge_id_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.verify_challenge(
        code: "897792"
      )
    end
    assert_equal "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments", err.message
  end

  def test_verify_challenge_missing_all_arguments_raises_error
    err = assert_raises(ArgumentError) do
      WorkOS::MFA.verify_challenge
    end
    assert_equal "Incomplete arguments: 'authentication_challenge_id' and 'code' are required arguments", err.message
  end

  def test_get_factor_with_valid_id
    VCR.use_cassette "mfa/get_factor_valid" do
      factor = WorkOS::MFA.get_factor(
        id: "auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M"
      )
      assert_kind_of String, factor.id
    end
  end

  def test_get_factor_with_invalid_id
    VCR.use_cassette "mfa/get_factor_invalid" do
      assert_raises(WorkOS::NotFoundError) do
        WorkOS::MFA.get_factor(
          id: "auth_factor_invalid"
        )
      end
    end
  end

  def test_delete_factor
    VCR.use_cassette "mfa/delete_factor" do
      response = WorkOS::MFA.delete_factor(
        id: "auth_factor_01FZ4WMXXA09XF6NK1XMKNWB3M"
      )
      assert_equal true, response
    end
  end
end
