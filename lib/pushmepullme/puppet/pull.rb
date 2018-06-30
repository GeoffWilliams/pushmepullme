require 'open-uri'
require 'json'
module PushMePullMe
  module Puppet
    module Pull
      FORGE_BASEURL="https://forge.puppet.com/v3"


      def self.md5(local_file, file_md5)
        authentic = Digest::MD5.file(local_file).hexdigest == file_md5
        authentic
      end

      # Convert a puppetfile line:
      #   mod 'beergeek-chronyd', '0.1.2'
      # into a slug:
      #   beergeek-chronyd-0.1.2
      #
      # If this is impossible raise an error...
      def self.puppetfile_to_slug(line)
        regexp = /^mod\s+('|")([^-]+-[^-]+)('|")\s*,\s*('|")(\d+\.\d+\.\d+)('|")\s*$/

        if line =~ regexp
          slug = line.gsub(regexp, '\2-\5')
        else
          slug = false
        end

        slug
      end

      def self.mk_download_dir(download_dir)
        if ! File.directory? download_dir
          Dir.mkdir(download_dir)
        end
      end

      # download the puppet module by munging the module name into a URL. The puppet forge
      # provides a rest api to work out things like latest version, etc and provides a ruby
      # gem to access but since we force users to specify a version lets do things the easy
      # way
      def self.download_module(download_dir, slug)
        status = 255
        begin
          mk_download_dir(download_dir)

          tarball = "#{slug}.tar.gz"
          local_file  = File.join(download_dir, tarball)

          # Example file URL
          # https://forge.puppet.com/v3/files/puppetlabs-stdlib-4.24.0.tar.gz
          remote_file = "#{FORGE_BASEURL}/files/#{tarball}"

          # Example metadata URL
          # https://forgeapi.puppetlabs.com:443/v3/releases/puppetlabs-ntp-1.0.0
          metadata_url = "#{FORGE_BASEURL}/releases/#{slug}"
          request_url = metadata_url

          #
          # metadata check
          #

          json = JSON.parse(open(request_url, "r").read)
          file_md5 = json['file_md5']
          Escort::Logger.output.puts "#{slug} REMOTE MD5 #{file_md5}"

          #
          # file download
          #
          if File.file?(local_file) && md5(local_file, file_md5)
            Escort::Logger.output.puts "already downloaded and verified"
          else

            Escort::Logger.output.puts "Downloading #{slug}"
            request_url = remote_file
            open(request_url, "rb") do |r|
              File.open(local_file, "wb") do |f|
                f.write(r.read)
              end
            end
            if md5(local_file, file_md5)
              Escort::Logger.output.puts "download verified OK"
            else
              # file is bogus - move out of way and inform user
              bogus_file = "#{local_file}.nouse"
              FileUtils.mv(local_file, bogus_file)
              Escort::Logger.error.error "Downloaded file #{bogus_file} is not #{file_md5} - interrupted or bogus?"
              status = 0
            end
          end
        rescue SocketError, OpenURI::HTTPError => e
          Escort::Logger.error.error "Error downloading #{request_url} -- #{e.message}"
          status = 1
        rescue Errno::EACCES => e
          Escort::Logger.error.error "Permissions error writing #{remote_file} -- #{e.message}"
          status = 2
        rescue Exception => e
          Escort::Logger.error.error "please come up with a better error for:", e
          status = 100
        end
        status
      end

      def self.process_puppetfile(download_dir, puppetfile)
        status = 255
        puppet_modules = []
        begin
          # Read the puppetfile and find the modules
          mk_download_dir(download_dir)
          File.readlines(puppetfile).reject { |line|
            !(line =~ /^mod/)
          }.each { |line|
            # your line MUST match the regexp to be included and must include a version
            slug = puppetfile_to_slug(line)
            if slug
              puppet_modules << slug
            else
              Escort::Logger.error.error "Skipped invalid Puppetfile mod: #{line.strip}"
            end
          }

          # now just download each individual module
          puppet_modules.each { |puppet_module|
            download_module(download_dir, puppet_module)
          }
        rescue Exception => e
          puts e.backtrace
          Escort::Logger.error.error "please come up with a better error for: #{e.message}"
        end
        status
      end


    end
  end
end