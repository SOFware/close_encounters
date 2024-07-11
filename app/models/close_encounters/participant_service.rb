module CloseEncounters
  class ParticipantService < ApplicationRecord
    has_many :events,
      inverse_of: :participant_service,
      class_name: "CloseEncounters::ParticipantEvent"

    validates :name, presence: true

    # if the table exists, then we can check the column type
    if connection.table_exists?(table_name) && (
      columns_hash = connection.schema_cache.columns_hash(table_name)
    )
      if columns_hash["connection_info"].type == :text
        serialize :connection_info, coder: JSON
      end
    end

    # ONLY encrypt if you have the necessary keys
    if Rails.application.credentials.close_encounters_encryption_key.present?
      encrypts :connection_info
    end
  end
end
