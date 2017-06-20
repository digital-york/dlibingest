namespace :dlibworkflow do
  require 'nokogiri'
  require 'yaml'

  solrconfig = YAML.load_file('config/solr.yml')
  SOLR       = solrconfig[Rails.env]['url']

  def self.user
    userid = 1
    user   = User.find(userid)
  end

  def self.default_permission
    "public"
  end

  desc "Create YODL collections from Fedora 3 repository"
  task create_collections: :environment do
    #top_cols_xpath = "/collections/collection[@pid='YODL']/collection[@pid='york:822269']/collection[@pid='york:815851']"
    top_cols_xpath = "/collections/collection[@pid='YODL']/collection[@pid='york:822269']/collection[@pid='york:11049']"

    doc      = Nokogiri::XML(File.open(Rails.root + 'lib/assets/lists/collections.xml'))
    top_cols = doc.xpath(top_cols_xpath)
    top_cols.each do |col|
      puts 'Creating ' + col.attr('label')
      col_obj = Collection.new
      col_obj.title     = [col.attr('label')]
      col_obj.former_id = [col.attr('pid')]
      col_obj.depositor = self.user.email

      #TODO: get permission from OLD Fedora Repository


      permission        = self.default_permission
      BasicProcessor.assign_permissions(user, permission, col_obj)
      col_obj.save!
      puts 'Created collection: ' + col_obj.id

      create_sub_collections(col_obj, col, '  ')
    end

  end

  def create_sub_collections(parent_obj, parent_col, indent='  ')
    sub_cols = parent_col.xpath('collection')
    sub_cols.each do |sub_col|
      puts indent + 'Creating ' + sub_col.attr('label')
      sub_col_obj = Collection.new
      sub_col_obj.title     = [sub_col.attr('label')]
      sub_col_obj.depositor = self.user.email

      #TODO: get permission from OLD Fedora Repository


      permission            = self.default_permission
      BasicProcessor.assign_permissions(user, permission, sub_col_obj)
      sub_col_obj.save!
      puts indent + 'Created collection: ' + sub_col_obj.id
      parent_obj.members << sub_col_obj
      puts indent + 'Added ' + sub_col_obj.id + ' into ' + parent_obj.id

      create_sub_collections(sub_col_obj, sub_col, indent + '  ')
    end
  end

end
