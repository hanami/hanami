Hanami::Model.migration do
  change do
    User.new

    create_table :users do
      primary_key :id
      column :name, String
    end
  end
end
