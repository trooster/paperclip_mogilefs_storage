module Paperclip
  module Storage
    module Mogilefs
      
      RETRIES_ON_BROKEN_SOCKET = 2 # 3 tries in total

      def self.extended base
        begin
          require 'mogilefs'
        rescue LoadError => e
          e.message << " (You may need to install the mogilefs-client gem)"
          raise e
        end

        base.instance_eval do
            @mogilefs_options = parse_options(File.join(Rails.root, "config", "mogilefs.yml"))
            @mogilefs_connection = @mogilefs_options[:connection]
            @mogilefs_class = @options[:mogilefs][:class] || @mogilefs_options[:class ] || "file"
            @mogilefs = MogileFS::MogileFS.new(:domain => @mogilefs_connection[:domain.to_s], :hosts => @mogilefs_connection[:hosts.to_s])
          end
      end

      def exists?(style = default_style)
        retry_on_broken_socket do
          @mogilefs.get_paths(url(style)).any?
        end
        rescue MogileFS::Backend::UnknownKeyError
          false
      end

      def to_file(style = default_style)
        if @queued_for_write[style]
          @queued_for_write[style]
        else
          retry_on_broken_socket do
            StringIO.new(@mogilefs.get_file_data(url(style)))
          end
        end
      end
      alias_method :to_io, :to_file

      def flush_writes #:nodoc:
        @queued_for_write.each do |style, io|
          Paperclip.log("Saving #{url(style)} to MogileFS")
          begin
            retry_on_broken_socket do
              begin
                io.open if io.closed? # Reopen IO to avoid empty_file error
                @mogilefs.store_file(url(style), @mogilefs_class, io)
              ensure
                io.close
              end
            end
          ensure
            io.close
          end
        end
        @queued_for_write = {}
      end

      def flush_deletes #:nodoc:
        @queued_for_delete.each do |path|
          Paperclip.log("Deleting #{path} from MogileFS")
          begin
            retry_on_broken_socket do
              @mogilefs.delete(path)
            end
          rescue MogileFS::Backend::UnknownKeyError
            Paperclip.logger.error("[paperclip] Error: #{path} not found in MogileFS")
          end
        end
        @queued_for_delete = []
      end

      # Don't include timestamp by default
      def url(style = default_style, include_updated_timestamp = false)
        super(style, include_updated_timestamp)
      end

      # Use url instead of path while queuing attachments for delete
      def queue_existing_for_delete #:nodoc:
        return unless file?
        @queued_for_delete += [:original, *@styles.keys].uniq.map do |style|
          url(style) if exists?(style)
        end.compact
        instance_write(:file_name, nil)
        instance_write(:content_type, nil)
        instance_write(:file_size, nil)
        instance_write(:updated_at, nil)
      end
   

      def retry_on_broken_socket
        retries = 0
        begin
          yield
        rescue MogileFS::UnreadableSocketError => e
          retries += 1
          if retries <= RETRIES_ON_BROKEN_SOCKET
            Paperclip.logger.error("[paperclip] MogileFS socket broken. Retrying (#{retries}/#{RETRIES_ON_BROKEN_SOCKET})...")
             @mogilefs = nil
            retry
          else
            Paperclip.logger.error("[paperclip] MogileFS socket broken. Out of retries (#{retries}/#{RETRIES_ON_BROKEN_SOCKET})! Exiting...")
            raise e
          end
        end
      end

      def parse_options options
        options = find_options(options).stringify_keys
        (options[RAILS_ENV] || options).symbolize_keys
      end
      
      def find_options options
        case options
        when File
          YAML::load(ERB.new(File.read(options.path)).result)
        when String
          YAML::load(ERB.new(File.read(options)).result)
        when Hash
          options
        else
          raise ArgumentError, "Credentials are not a path, file, or hash."
        end
      end
      private :find_options

    end
  end
end