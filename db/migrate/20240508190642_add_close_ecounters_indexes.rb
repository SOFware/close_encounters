class AddCloseEcountersIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    options = if self.class.adapter_name.match?(/postgres/i)
      {algorithm: :concurrently}
    else
      {}
    end

    add_index :close_encounters_participant_services,
      :name,
      unique: true,
      **options
  end
end
