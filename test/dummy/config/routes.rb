Rails.application.routes.draw do
  mount CloseEncounters::Engine => "/close_encounters"
end
