require 'open-uri'
require 'net/http'
module PushMePullMe
  module Puppet
    module Push

      # convert a path:
      #   /tmp/crayfishx-firewalld-3.4.0.tar.gz
      # to a slug:
      #   crayfishx-firewalld-3.4.0
      def self.path_to_slug(path)
        File.basename(path).gsub(".tar.gz","")
      end


      def self.upload_file(baseurl, path)
        # work out a nice place to upload us to. artifactory doesn't care about directories, it uses the metadata to
        # serve the correct file at all times but lets split things up for neatness
        slug = path_to_slug(path)
        slug_split = slug.split("-")

        module_uri = "#{baseurl}/#{slug_split[0]}/#{slug_split[1]}/#{File.basename(path)}"

        uri = URI.parse(module_uri)
        userinfo = uri.userinfo.split(":")

        #
        # check - module already exists? (to re-upload delete yourself and re-run)
        #
        req = Net::HTTP::Head.new(uri.path)
        # Extract credentials for upload from baseurl since net-http ignores them
        # username and password extractable from URI but need to be split up again to be fed into the request
        req.basic_auth userinfo[0], userinfo[1]

        res = Net::HTTP.new(uri.host, uri.port).start {|http|
          http.request(req)
        }

        if res.code == '200'
          Escort::Logger.output.puts "Skipping #{slug} - already exists"
          status = 0
        else

          #
          # puppet module upload
          #

          # Do PUT with the file data - as instructed on the set-me-up page :)
          req = Net::HTTP::Put.new(uri.path)
          req.basic_auth userinfo[0], userinfo[1]
          req.body = File.read(path)

          res = Net::HTTP.new(uri.host, uri.port).start {|http|
            http.request(req)
          }

          if res.code == '201'
            status = 0
            Escort::Logger.output.puts "created OK"
          else
            status = 1
            Escort::Logger.error.error "Error uploading: #{res.code}: #{res.body || 'reply was empty'}"
          end
        end
        status
      end

      def self.upload_dir(baseurl, dir)
        status = 0
        Dir.glob("#{dir}/*.tar.gz").each do|f|
          status += upload_file(baseurl, f)
        end

        status
      end

    end
  end
end