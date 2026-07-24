module CloseEncounters
  class ParticipantEvent < ApplicationRecord
    belongs_to :participant_service,
      inverse_of: :events,
      class_name: "CloseEncounters::ParticipantService",
      foreign_key: "close_encounters_participant_service_id"

    # id breaks ties so "newest" is deterministic when two events share a
    # created_at (common under bulk inserts and sub-second traffic).
    scope :newest, -> { order(created_at: :desc, id: :desc).limit(1) }

    unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
      serialize :metadata, coder: JSON
    end

    def verified?
      !!metadata.to_h.dig("verified")
    end
  end
end
