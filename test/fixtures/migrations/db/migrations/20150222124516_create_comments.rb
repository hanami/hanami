class CreateComments < Lotus::Model::Migration
  def up
    create_table :comments do
      primary_key :id
      String :content
    end
  end

  def down
    drop_table :comments
  end
end
