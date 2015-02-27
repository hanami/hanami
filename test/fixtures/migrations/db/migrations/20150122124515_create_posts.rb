class CreatePosts < Lotus::Model::Migration
  def up
    create_table :posts do
      primary_key :id
      String :title
      String :content
    end
  end

  def down
    drop_table :posts
  end
end
