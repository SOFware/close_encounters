module CloseEncounters
  class ParticipantService < ApplicationRecord
    has_many :events,
      inverse_of: :participant_service,
      class_name: "CloseEncounters::ParticipantEvent"

    validates :name, presence: true

    # ONLY encrypt if you have the necessary keys
    if Rails.application.credentials.close_encounters_encryption_key.present?
      encrypts :connection_info
    end

    def connection_info
      if super.is_a?(String)
        JSON.parse(super)
      else
        super
      end
    end

    def connection_info=(value)
      super(value.to_json)
    end
  end
end
