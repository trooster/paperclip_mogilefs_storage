module MogileFSConnect
  extend self 
  
  # singleton
  
  def connect_tracker
    @mogilefs ||= MogileFS::MogileFS.new(connection_params)
    @mogilefs
  end
  
  def get_class
     @getclass ||= mogilefs_options[:class ]
     @getclass
  end
  
  def connection_params
    connection_options = mogilefs_options[:connection]
    connection_params = {:domain => connection_options[:domain.to_s], :hosts => connection_options[:hosts.to_s]}
    connection_params
  end
  
  def mogilefs_options
    @mogilefs_options ||= YAML.load_file(File.join(Rails.root, "config", "mogilefs.yml"))[RAILS_ENV].symbolize_keys
    @mogilefs_options
  end
   
end