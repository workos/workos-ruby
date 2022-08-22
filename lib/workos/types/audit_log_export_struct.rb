# frozen_string_literal: true
# typed: strict

module WorkOS
  module Types
    # This AuditLogExportStruct acts as a typed interface
    # for the AuditLogExport class
    class AuditLogExportStruct < T::Struct
      const :object, String
      const :id, String
      const :state, String
      const :url, T.nilable(String)
      const :created_at, String
      const :updated_at, String
    end
  end
end
