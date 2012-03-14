module Setup
  # Create / Delete entire DB
  def create
    begin
      puts "Creating..."
      ActiveRecord::Schema.define do
        create_table :test_relations do |table|
          table.column :test_case_id, :integer
          table.column :test_collection_id, :integer
        end

        create_table :general_configurations do |table|
          table.column :server, :string
          table.column :devkey, :string
          table.column :smtp_host, :string
          table.column :smtp_recipient, :string
        end

        create_table :project_configurations do |table|
          table.column :project, :string # aka prefix
          table.column :vm_user, :string
          table.column :vm_password, :string
          table.column :ssh_key_path, :string
          table.column :ssh_key_pw, :string
          table.column :base_path, :string
          table.column :output_path, :string
        end

        create_table :test_collections do |table|
          table.column :project, :string
          table.column :project_id, :string
          table.column :plan, :string
          table.column :plan_id, :string
          table.column :build, :string
          table.column :collection_id, :string
        end

        create_table :test_cases do |table|
          table.column :urgency, :string
          table.column :name, :string
          table.column :file, :string
          table.column :external_id, :string
          table.column :platform_id, :string
        end

      end

    rescue ActiveRecord::StatementInvalid
      # Table already created
      puts "Setup already done. Destroy tables first before creating"
    end


  end
  module_function :create

  def reset
    self.destroy
    self.create
    self.seed
  end
  module_function :reset

  def seed
    puts "Seeding..."
    GeneralConfiguration.create_or_update(:server => "http://testlink:81",:devkey => "029e19a6277c6c5b87b824db9a2707f7" )
    ProjectConfiguration.create_or_update(:project => 'DPS')
    #TestCollection.create(:project => 'DPS')
    #TestCase.create(:external_id => 123,:name => 'blarg')

  end
  module_function :seed

  def destroy
    begin
      puts "Destroying..."
      ActiveRecord::Schema.define do
        drop_table :general_configurations
        drop_table :project_configurations
        drop_table :test_relations
        drop_table :test_collections
        drop_table :test_cases
      end
    rescue ActiveRecord::StatementInvalid
      # Table already created
      puts "No tables to destroy, create tables before destroying them."
    end
  end
  module_function :destroy
end