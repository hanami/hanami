RSpec.describe "Components: finalizers", type: :integration do
  it "ensures to load components once" do
    with_project do
      write "config/initializers/counter.rb", <<-EOF
class Counter
  @counter = 0

  def self.counter
    @counter
  end

  def self.increment!
    @counter += 1
  end
end

Counter.increment!
EOF

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('finalizers')

      counter = Counter.counter

      # Simulate accidental double trigger
      Hanami::Components.resolve('finalizers')

      # counter shouldn't have been changed
      expect(Counter.counter).to eq(counter)
    end
  end
end
