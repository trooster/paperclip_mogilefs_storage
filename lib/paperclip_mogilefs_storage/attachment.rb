module Paperclip
  class Attachment
    
    def mogilefs_url style = default_style
      mogilefs = MogileFSConnect.connect_tracker
      url = original_filename.nil? ? interpolate(@default_url, style) : interpolate(@url, style)
      mogilefs.get_paths(url)[0]
    end
  
  end
end