# frozen_string_literal: true

require "test_helper"
require "json"
require "openssl"

class TestWebhooks < WorkOS::TestCase
  def setup
    super
    @payload = File.read("#{TEST_ROOT}/fixtures/webhook_payload.txt")
    @secret = "secret"
    @timestamp = Time.at(Time.now.to_i * 1000)
    unhashed_string = "#{@timestamp.to_i}.#{@payload}"
    digest = OpenSSL::Digest.new("sha256")
    @signature_hash = OpenSSL::HMAC.hexdigest(digest, @secret, unhashed_string)
    @expectation = {
      id: "directory_user_01FAEAJCR3ZBZ30D8BD1924TVG",
      state: "active",
      emails: [{
        type: "work",
        value: "blair@foo-corp.com",
        primary: true
      }],
      idp_id: "00u1e8mutl6wlH3lL4x7",
      object: "directory_user",
      username: "blair@foo-corp.com",
      last_name: "Lunchford",
      first_name: "Blair",
      directory_id: "directory_01F9M7F68PZP8QXP8G7X5QRHS7",
      raw_attributes: {
        name: {
          givenName: "Blair",
          familyName: "Lunchford",
          middleName: "Elizabeth",
          honorificPrefix: "Ms."
        },
        title: "Developer Success Engineer",
        active: true,
        emails: [{
          type: "work",
          value: "blair@foo-corp.com",
          primary: true
        }],
        groups: [],
        locale: "en-US",
        schemas: [
          "urn:ietf:params:scim:schemas:core:2.0:User",
          "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
        ],
        userName: "blair@foo-corp.com",
        addresses: [{
          region: "CA",
          primary: true,
          locality: "San Francisco",
          postalCode: "94016"
        }],
        externalId: "00u1e8mutl6wlH3lL4x7",
        displayName: "Blair Lunchford",
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
          manager: {
            value: "2",
            displayName: "Kate Chapman"
          },
          division: "Engineering",
          department: "Customer Success"
        }
      }
    }
  end

  # ---- construct_event: signature header failures ----

  def test_construct_event_with_empty_header
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "",
        secret: @secret
      )
    end
    assert_equal "Unable to extract timestamp and signature hash from header", err.message
  end

  def test_construct_event_with_empty_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=",
        secret: @secret
      )
    end
    assert_equal "No signature hash found with expected scheme v1", err.message
  end

  def test_construct_event_with_incorrect_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=99999",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_construct_event_with_incorrect_payload
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: "invalid",
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_construct_event_with_incorrect_webhook_secret
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: "invalid"
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_construct_event_with_timestamp_outside_tolerance
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i - (200 * 1000)}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Timestamp outside the tolerance zone", err.message
  end

  # ---- construct_event: success cases ----

  def test_construct_event_with_correct_payload_sig_header_and_secret
    webhook = WorkOS::Webhooks.construct_event(
      payload: @payload,
      sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
      secret: @secret
    )

    assert_equal @expectation, webhook.data
    assert_equal "dsync.user.created", webhook.event
    assert_equal "wh_123", webhook.id
  end

  def test_construct_event_with_correct_payload_sig_header_secret_and_tolerance
    webhook = WorkOS::Webhooks.construct_event(
      payload: @payload,
      sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
      secret: @secret,
      tolerance: 300
    )

    assert_equal @expectation, webhook.data
    assert_equal "dsync.user.created", webhook.event
    assert_equal "wh_123", webhook.id
  end

  # ---- verify_header: signature header failures ----

  def test_verify_header_with_empty_header
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: @payload,
        sig_header: "",
        secret: @secret
      )
    end
    assert_equal "Unable to extract timestamp and signature hash from header", err.message
  end

  def test_verify_header_with_empty_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=",
        secret: @secret
      )
    end
    assert_equal "No signature hash found with expected scheme v1", err.message
  end

  def test_verify_header_with_incorrect_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=99999",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_verify_header_with_incorrect_payload
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: "invalid",
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_verify_header_with_incorrect_webhook_secret
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: "invalid"
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_verify_header_with_timestamp_outside_tolerance
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.verify_header(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i - (200 * 1000)}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Timestamp outside the tolerance zone", err.message
  end

  # ---- verify_header: success ----

  def test_verify_header_returns_true_when_signature_is_valid
    WorkOS::Webhooks.verify_header(
      payload: @payload,
      sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
      secret: @secret
    )
  end

  # ---- get_timestamp_and_signature_hash: signature header failures ----

  def test_get_timestamp_and_signature_hash_with_empty_header
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "",
        secret: @secret
      )
    end
    assert_equal "Unable to extract timestamp and signature hash from header", err.message
  end

  def test_get_timestamp_and_signature_hash_with_empty_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=",
        secret: @secret
      )
    end
    assert_equal "No signature hash found with expected scheme v1", err.message
  end

  def test_get_timestamp_and_signature_hash_with_incorrect_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=99999",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_get_timestamp_and_signature_hash_with_incorrect_payload
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: "invalid",
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_get_timestamp_and_signature_hash_with_incorrect_webhook_secret
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: "invalid"
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_get_timestamp_and_signature_hash_with_timestamp_outside_tolerance
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i - (200 * 1000)}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Timestamp outside the tolerance zone", err.message
  end

  # ---- get_timestamp_and_signature_hash: success ----

  def test_get_timestamp_and_signature_hash_returns_timestamp_and_signature
    timestamp_int = @timestamp.to_i
    timestamp_and_signature = WorkOS::Webhooks.get_timestamp_and_signature_hash(
      sig_header: "t=#{timestamp_int}, v1=#{@signature_hash}"
    )

    assert_equal [timestamp_int.to_s, @signature_hash], timestamp_and_signature
  end

  # ---- compute_signature: signature header failures ----

  def test_compute_signature_with_empty_header
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "",
        secret: @secret
      )
    end
    assert_equal "Unable to extract timestamp and signature hash from header", err.message
  end

  def test_compute_signature_with_empty_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=",
        secret: @secret
      )
    end
    assert_equal "No signature hash found with expected scheme v1", err.message
  end

  def test_compute_signature_with_incorrect_signature_hash
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=99999",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_compute_signature_with_incorrect_payload
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: "invalid",
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_compute_signature_with_incorrect_webhook_secret
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i}, v1=#{@signature_hash}",
        secret: "invalid"
      )
    end
    assert_equal "Signature hash does not match the expected signature hash for payload", err.message
  end

  def test_compute_signature_with_timestamp_outside_tolerance
    err = assert_raises(WorkOS::SignatureVerificationError) do
      WorkOS::Webhooks.construct_event(
        payload: @payload,
        sig_header: "t=#{@timestamp.to_i - (200 * 1000)}, v1=#{@signature_hash}",
        secret: @secret
      )
    end
    assert_equal "Timestamp outside the tolerance zone", err.message
  end

  # ---- compute_signature: success ----

  def test_compute_signature_returns_computed_signature
    timestamp_int = @timestamp.to_i
    signature = WorkOS::Webhooks.compute_signature(
      timestamp: timestamp_int.to_s,
      payload: @payload,
      secret: @secret
    )

    assert_equal @signature_hash, signature
  end
end
