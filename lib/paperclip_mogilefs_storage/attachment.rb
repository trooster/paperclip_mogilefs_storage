module Paperclip
  class Attachment

    def mogilefs_url style = default_style
      mogilefs = MogileFSConnect.connect_tracker
      url = original_filename.nil? ? interpolate(@default_url, style) : interpolate(@url, style)
      mogilefs.get_paths(url)[0]
      rescue MogileFS::Backend::UnknownKeyError
        Paperclip.logger.error("[paperclip] Error: #{url} not found in MogileFS")
    end

    def mogilefs_get_paths style = default_style
      mogilefs = MogileFSConnect.connect_tracker
      url = original_filename.nil? ? interpolate(@default_url, style) : interpolate(@url, style)
      mogilefs.get_paths(url)
      rescue MogileFS::Backend::UnknownKeyError
        Paperclip.logger.error("[paperclip] Error: #{url} not found in MogileFS")
    end
  
  end
end