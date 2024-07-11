module CloseEncounters
  class ParticipantEvent < ApplicationRecord
    belongs_to :participant_service,
      inverse_of: :events,
      class_name: "CloseEncounters::ParticipantService",
      foreign_key: "close_encounters_participant_service_id"

    scope :newest, -> { order(created_at: :desc).limit(1) }
  end
end
