module CloseEncounters
  class ParticipantEvent < ApplicationRecord
    belongs_to :participant_service, inverse_of: :events, class_name: "CloseEncounters::ParticipantService"

    scope :newest, -> { order(created_at: :desc).first }
  end
end
